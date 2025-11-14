#!/usr/bin/env bash

# Per-sequence probe to measure runtime, then REPEATS runs sampling at midpoint (50%).
# CSV header:
# timestamp,run,seq_name,mode,sample_type,temp_C,vcgencmd_throttled,cpu_freq_MHz,cpu_percent,ram_used_MB,process_cpu_percent,process_mem_MB

# Usage:
#   REPEATS=5 COOLDOWN_SEC=120 ./evaluate_thermal_conditions.sh

# Notes:
#  - A probe run (run=0) is executed per sequence to measure runtime & compute midpoint
#  - If you prefer the probe to count toward REPEATS, reduce REPEATS by 1 accordingly
#  - If you later add a power meter, we can re-add a power column

set -euo pipefail
IFS=$'\n\t'

ROOT="${HOME}/ros2_test"
ORBSLAM_EXE_DIR="${ROOT}/src/ORB_SLAM3/Examples"
VOCAB="${ROOT}/src/ORB_SLAM3/Vocabulary/ORBvoc.txt"
RESULTS_DIR="${ROOT}/results"

# Full worklist for which Thermal data had been recorded
WORKLIST_INLINE=(
  "TUM,rgbd_dataset_freiburg1_desk,rgbd"
  "TUM,rgbd_dataset_freiburg1_floor,mono"
  "TUM,rgbd_dataset_freiburg3_nostructure_notexture_far,rgbd"
  "EuRoC,MH01,mono"
  "EuRoC,MH05,mono"
  "KITTI,00,stereo"
)

# Tunables (override via env)
REPEATS="${REPEATS:-5}"             # number of measured runs per sequence (probe is run 0 extra)
COOLDOWN_SEC="${COOLDOWN_SEC:-160}" # same as other evaluation scripts
# If you want a minimum DURING_DELAY (some sequences are very short), set MIN_DURING (seconds)
MIN_DURING="${MIN_DURING:-1}"

# Runtime env for ORB-SLAM3 native binaries (adjust LD_PRELOAD if necessary)
export DISPLAY=${DISPLAY:-:0}
export LIBGL_ALWAYS_INDIRECT=1
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330
export LD_PRELOAD="/usr/lib/aarch64-linux-gnu/libGL.so"
export LD_LIBRARY_PATH="${ROOT}/src/ORB_SLAM3/lib:${ROOT}/src/ORB_SLAM3/Thirdparty/DBoW2/lib:${ROOT}/src/ORB_SLAM3/Thirdparty/g2o/lib:${LD_LIBRARY_PATH:-}"

# If you need to source ROS/workspace local_setup, uncomment and ensure safe:
# if [ -f "${ROOT}/install/local_setup.bash" ]; then
#   set +u
#   # shellcheck disable=SC1090
#   source "${ROOT}/install/local_setup.bash" || echo "Warning: failed sourcing local_setup.bash"
#   set -u
# fi

now_iso() { date --iso-8601=seconds; }

mkdir -p "$RESULTS_DIR"

write_header() {
  local out="$1"; local f="$out/thermal_log.csv"
  if [ ! -f "$f" ]; then
    echo "timestamp,run,seq_name,mode,sample_type,temp_C,vcgencmd_throttled,cpu_freq_MHz,cpu_percent,ram_used_MB,process_cpu_percent,process_mem_MB" > "$f"
  fi
}

sample_once() {
  local runnum="$1"; local seq="$2"; local mode="$3"; local out="$4"; local sample_type="$5"
  local ts
  ts="$(now_iso)"

  # temp
  if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "")
    temp_c=$( [ -n "$temp_raw" ] && awk "BEGIN{printf \"%.2f\", $temp_raw/1000}" || echo "NA" )
  elif command -v vcgencmd >/dev/null 2>&1; then
    temp_c=$(vcgencmd measure_temp 2>/dev/null | sed -n "s/temp=//;s/'C//;p" || echo "NA")
  else
    temp_c="NA"
  fi

  # throttled
  if command -v vcgencmd >/dev/null 2>&1; then
    thr=$(vcgencmd get_throttled 2>/dev/null | awk -F= '{print $2}' || echo "NA")
  else
    thr="NA"
  fi

  # cpu freq
  if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]; then
    cpu_freq_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo "")
    cpu_freq_mhz=$( [ -n "$cpu_freq_khz" ] && awk "BEGIN{printf \"%.0f\", $cpu_freq_khz/1000}" || echo "NA" )
  elif command -v vcgencmd >/dev/null 2>&1; then
    cpu_freq_mhz=$(vcgencmd measure_clock arm 2>/dev/null | sed -n 's/clock=//;p' | awk '{printf "%.0f", $1/1000000}' 2>/dev/null || echo "NA")
  else
    cpu_freq_mhz="NA"
  fi

  # cpu percent
  cpu_percent="NA"
  if command -v mpstat >/dev/null 2>&1; then
    cpu_percent=$(mpstat 1 1 | awk '/all/ {printf "%.1f", 100 - $12}' || echo "NA")
  else
    cpu_idle=$(top -bn1 | awk -F',' '/Cpu/ {gsub(/[^0-9.]/,"",$4); print $4}' || echo "")
    cpu_percent=$( [ -n "$cpu_idle" ] && awk "BEGIN{printf \"%.1f\", 100 - $cpu_idle}" || echo "NA")
  fi

  # RAM used MB
  ram_used_mb=$(free -m | awk '/Mem:/ {print $3}' 2>/dev/null || echo "NA")

  # process metrics (check ORB-SLAM3 pid)
  proc_cpu="NA"; proc_mem_mb="NA"
  if [ -n "${RUN_PID:-}" ] 2>/dev/null && kill -0 "$RUN_PID" 2>/dev/null; then
    pid="$RUN_PID"
  else
    pid=$(pgrep -f mono_tum || true)
    pid=${pid:-$(pgrep -f rgbd_tum || true)}
    pid=${pid:-$(pgrep -f mono_euroc || true)}
    pid=${pid:-$(pgrep -f stereo_euroc || true)}
    pid=${pid:-$(pgrep -f mono_kitti || true)}
  fi
  if [ -n "${pid:-}" ]; then
    proc_cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | awk '{printf "%.1f", $1}' || echo "NA")
    proc_rss=$(ps -p "$pid" -o rss= 2>/dev/null | awk '{print $1}' || echo "")
    proc_mem_mb=$( [ -n "$proc_rss" ] && awk "BEGIN{printf \"%.1f\", $proc_rss/1024}" || echo "NA")
  fi

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$ts" "$runnum" "$seq" "$mode" "$sample_type" "$temp_c" "$thr" "$cpu_freq_mhz" "$cpu_percent" "$ram_used_mb" "$proc_cpu" "$proc_mem_mb" \
    >> "$out/thermal_log.csv"
}

# Build native ORB-SLAM3 command string for dataset/seq/mode (use_viewer=false)
build_slam_cmd() {
  local ds="$1"; local seq="$2"; local mode="$3"
  case "$ds" in
    TUM)
      if [[ "$mode" =~ ^(mono|monocular)$ ]]; then
        echo "${ORBSLAM_EXE_DIR}/Monocular/mono_tum ${VOCAB} ${ORBSLAM_EXE_DIR}/Monocular/TUM1.yaml ${ROOT}/datasets/TUM/${seq} false"
      elif [[ "$mode" =~ ^(rgbd)$ ]]; then
        echo "${ORBSLAM_EXE_DIR}/RGB-D/rgbd_tum ${VOCAB} ${ORBSLAM_EXE_DIR}/RGB-D/TUM1.yaml ${ROOT}/datasets/TUM/${seq} ${ROOT}/datasets/TUM/${seq}/associate.txt false"
      else
        return 1
      fi
      ;;
    EuRoC)
      if [[ "$mode" =~ ^(mono|monocular)$ ]]; then
        echo "${ORBSLAM_EXE_DIR}/Monocular/mono_euroc ${VOCAB} ${ORBSLAM_EXE_DIR}/Monocular/EuRoC.yaml ${ROOT}/datasets/EuRoC/${seq} ${ORBSLAM_EXE_DIR}/Monocular/EuRoC_TimeStamps/${seq}.txt false"
      elif [[ "$mode" =~ ^(stereo)$ ]]; then
        echo "${ORBSLAM_EXE_DIR}/Stereo/stereo_euroc ${VOCAB} ${ORBSLAM_EXE_DIR}/Stereo/EuRoC.yaml ${ROOT}/datasets/EuRoC/${seq} ${ROOT}/datasets/EuRoC/${seq}/mav0/${seq}.txt false"
      else
        return 1
      fi
      ;;
    KITTI)
      if [[ "$mode" =~ ^(mono|monocular)$ ]]; then
        echo "${ORBSLAM_EXE_DIR}/Monocular/mono_kitti ${VOCAB} ${ORBSLAM_EXE_DIR}/Monocular/KITTI00-02.yaml ${ROOT}/datasets/KITTI/dataset/sequences/${seq} ${seq} false"
      elif [[ "$mode" =~ ^(stereo)$ ]]; then
        echo "${ORBSLAM_EXE_DIR}/Stereo/stereo_kitti ${VOCAB} ${ORBSLAM_EXE_DIR}/Stereo/KITTI00-02.yaml ${ROOT}/datasets/KITTI/dataset/sequences/${seq} false"
      else
        return 1
      fi
      ;;
    *)
      return 1
      ;;
  esac
}

# main loop
echo "Starting thermal evaluation (midpoint/during sampling). REPEATS=${REPEATS}, COOLDOWN=${COOLDOWN_SEC}s"
for entry in "${WORKLIST_INLINE[@]}"; do
  IFS=',' read -r dataset seq mode <<< "$entry"
  dataset="$(echo "$dataset" | tr -d '[:space:]')"
  seq="$(echo "$seq" | tr -d '[:space:]')"
  mode="$(echo "$mode" | tr -d '[:space:]')"

  outdir="${RESULTS_DIR}/${dataset}/${seq}/${mode}"
  mkdir -p "$outdir"
  write_header "$outdir"

  echo "=== Sequence: ${dataset}/${seq}/${mode} ==="
  echo "  Probe run (run=0) to measure runtime..."

  # --- Probe run (run 0): measure runtime (before + after samples)
  sample_once 0 "$seq" "$mode" "$outdir" "before"
  PROBE_LOG="$outdir/probe_run_log.txt"
  SLAM_CMD="$(build_slam_cmd "$dataset" "$seq" "$mode")" || { echo "Unsupported combo ${dataset}/${seq}/${mode}; skipping"; continue; }
  echo "Probe command: $SLAM_CMD" > "$PROBE_LOG"
  START_SEC=$(date +%s.%N)
  bash -c "$SLAM_CMD" >> "$PROBE_LOG" 2>&1 || true
  END_SEC=$(date +%s.%N)
  DUR=$(awk "BEGIN{printf \"%.3f\", $END_SEC - $START_SEC}")
  sample_once 0 "$seq" "$mode" "$outdir" "after"
  echo "  Probe runtime (s): $DUR (saved in $PROBE_LOG)"
  # compute midpoint delay (seconds, integer)
  MID_DELAY=$(awk "BEGIN{d=$DUR/2; if (d < $MIN_DURING) d=$MIN_DURING; printf \"%d\", (d+0.5)}")
  echo "  Using MID_DELAY=${MID_DELAY}s for subsequent runs (50% of probe runtime)"

  # Save the measured duration for reference
  echo "$DUR" > "$outdir/probe_duration_seconds.txt"

  # Now measured REPEATS runs with midpoint sampling
  for ((run=1; run<=REPEATS; run++)); do
    echo "-- run $run of $REPEATS for ${seq} --"
    sample_once "$run" "$seq" "$mode" "$outdir" "before"

    RUN_LOG="$outdir/run_${run}_log.txt"
    echo "Command: $SLAM_CMD" > "$RUN_LOG"
    echo "Starting SLAM at $(now_iso)" >> "$RUN_LOG"
    bash -c "$SLAM_CMD" >> "$RUN_LOG" 2>&1 &
    RUN_PID=$!
    export RUN_PID
    echo "Launched SLAM (pid $RUN_PID)" >> "$RUN_LOG"

    # DURING sample at midpoint
    # Sleep MID_DELAY seconds (if the process exits early the during sample will still run and show NA for process fields)
    sleep "$MID_DELAY"
    sample_once "$run" "$seq" "$mode" "$outdir" "during"

    # wait for process exit
    wait "$RUN_PID" || true
    echo "Finished SLAM at $(now_iso)" >> "$RUN_LOG"
    sample_once "$run" "$seq" "$mode" "$outdir" "after"

    echo "Completed run $run. Results at: $outdir"
    echo "Cooldown ${COOLDOWN_SEC}s..."
    sleep "$COOLDOWN_SEC"
  done

  echo "Sequence ${seq} done. Probe duration: ${DUR}s, midpoint used: ${MID_DELAY}s"
done

echo "All sequences completed."
