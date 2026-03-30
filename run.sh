#!/usr/bin/env bash

# Shared Configuration
TASKS=(
    "LeIsaac-SO101-LiftCube-v0"
    "LeIsaac-SO101-PickOrange-v0"
    "LeIsaac-SO101-AssembleHamburger-v0"
    "LeIsaac-SO101-CleanToyTable-v0"
    "LeIsaac-SO101-FoldCloth-BiArm-v0"
)

# Default values
DEFAULT_TASK="LeIsaac-SO101-PickOrange-v0"

# Load environment variables if .env exists (used for sync)
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Help Function
show_help() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  play     Run teleoperation (keyboard/gamepad/leader arm)"
    echo "  replay   Replay recorded dataset"
    echo "  infer    Run policy inference (GR00T/LeRobot/OpenPI)"
    echo "  list     List all registered LeIsaac environments"
    echo "  sync     Sync logs from remote server"
    echo ""
    echo "Examples:"
    echo "  $0 play"
    echo "  $0 play --task LeIsaac-SO101-LiftCube-v0 --teleop_device gamepad"
    echo "  $0 play --task LeIsaac-SO101-PickOrange-v0 --record --num_demos 10"
    echo "  $0 replay --dataset_file ./datasets/pick_orange.hdf5"
    echo "  $0 infer --task LeIsaac-SO101-PickOrange-v0 --policy_type gr00tn1.5"
    echo ""
}

# ---------------------------------------------------------
# COMMAND: PLAY (Teleoperation)
# ---------------------------------------------------------
cmd_play() {
    local TASK="$DEFAULT_TASK"
    local TELEOP_DEVICE="keyboard"
    local NUM_ENVS=1
    local PORT="/dev/ttyACM0"
    local LEFT_ARM_PORT="/dev/ttyACM0"
    local RIGHT_ARM_PORT="/dev/ttyACM1"
    local STEP_HZ=60
    local RECORD=false
    local DATASET_FILE="./datasets/dataset.hdf5"
    local NUM_DEMOS=0
    local RESUME=false
    local USE_LEROBOT_RECORDER=false
    local LEROBOT_DATASET_REPO_ID=""
    local LEROBOT_DATASET_FPS=30
    local QUALITY=false
    local RECALIBRATE=false
    local USE_WEBRTC=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --task)                  TASK="$2"; shift 2 ;;
            --teleop_device)         TELEOP_DEVICE="$2"; shift 2 ;;
            --num_envs)              NUM_ENVS="$2"; shift 2 ;;
            --port)                  PORT="$2"; shift 2 ;;
            --left_arm_port)         LEFT_ARM_PORT="$2"; shift 2 ;;
            --right_arm_port)        RIGHT_ARM_PORT="$2"; shift 2 ;;
            --step_hz)               STEP_HZ="$2"; shift 2 ;;
            --record)                RECORD=true; shift ;;
            --dataset_file)          DATASET_FILE="$2"; shift 2 ;;
            --num_demos)             NUM_DEMOS="$2"; shift 2 ;;
            --resume)                RESUME=true; shift ;;
            --use_lerobot_recorder)  USE_LEROBOT_RECORDER=true; shift ;;
            --lerobot_dataset_repo_id) LEROBOT_DATASET_REPO_ID="$2"; shift 2 ;;
            --lerobot_dataset_fps)   LEROBOT_DATASET_FPS="$2"; shift 2 ;;
            --quality)               QUALITY=true; shift ;;
            --recalibrate)           RECALIBRATE=true; shift ;;
            --webrtc)                USE_WEBRTC=true; shift ;;
            *)                       echo "Unknown parameter for play: $1"; exit 1 ;;
        esac
    done

    local LIVESTREAM_PARAM=""
    local DISPLAY_MODE="GUI"
    if [ "$USE_WEBRTC" = true ]; then
        LIVESTREAM_PARAM="--livestream 2"
        DISPLAY_MODE="WebRTC"
    fi

    local QUALITY_PARAM=""
    if [ "$QUALITY" = true ]; then
        QUALITY_PARAM="--quality"
    fi

    local RECORD_PARAMS=""
    if [ "$RECORD" = true ]; then
        RECORD_PARAMS="--record --dataset_file $DATASET_FILE --num_demos $NUM_DEMOS"
        if [ "$RESUME" = true ]; then
            RECORD_PARAMS="$RECORD_PARAMS --resume"
        fi
        if [ "$USE_LEROBOT_RECORDER" = true ]; then
            RECORD_PARAMS="$RECORD_PARAMS --use_lerobot_recorder"
            if [ -n "$LEROBOT_DATASET_REPO_ID" ]; then
                RECORD_PARAMS="$RECORD_PARAMS --lerobot_dataset_repo_id $LEROBOT_DATASET_REPO_ID --lerobot_dataset_fps $LEROBOT_DATASET_FPS"
            fi
        fi
    fi

    local RECALIBRATE_PARAM=""
    if [ "$RECALIBRATE" = true ]; then
        RECALIBRATE_PARAM="--recalibrate"
    fi

    echo "Starting teleoperation..."
    echo "Task: $TASK"
    echo "Teleop Device: $TELEOP_DEVICE"
    echo "Num Envs: $NUM_ENVS"
    echo "Display: $DISPLAY_MODE"
    if [ "$RECORD" = true ]; then
        echo "Recording: enabled -> $DATASET_FILE"
    fi

    python scripts/environments/teleoperation/teleop_se3_agent.py \
        --task="$TASK" \
        --teleop_device="$TELEOP_DEVICE" \
        --num_envs $NUM_ENVS \
        --step_hz $STEP_HZ \
        --port "$PORT" \
        --left_arm_port "$LEFT_ARM_PORT" \
        --right_arm_port "$RIGHT_ARM_PORT" \
        --rendering_mode performance \
        --enable_cameras \
        $QUALITY_PARAM \
        $RECALIBRATE_PARAM \
        $RECORD_PARAMS \
        $LIVESTREAM_PARAM
}

# ---------------------------------------------------------
# COMMAND: REPLAY (Replay recorded dataset)
# ---------------------------------------------------------
cmd_replay() {
    local DATASET_FILE="./datasets/dataset.hdf5"
    local TASK=""
    local NUM_ENVS=1

    while [[ $# -gt 0 ]]; do
        case $1 in
            --dataset_file) DATASET_FILE="$2"; shift 2 ;;
            --task)         TASK="$2"; shift 2 ;;
            --num_envs)     NUM_ENVS="$2"; shift 2 ;;
            *)              echo "Unknown parameter for replay: $1"; exit 1 ;;
        esac
    done

    local TASK_PARAM=""
    if [ -n "$TASK" ]; then
        TASK_PARAM="--task $TASK"
    fi

    echo "Replaying dataset: $DATASET_FILE"

    python scripts/environments/teleoperation/replay.py \
        --dataset_file "$DATASET_FILE" \
        --num_envs $NUM_ENVS \
        $TASK_PARAM
}

# ---------------------------------------------------------
# COMMAND: INFER (Policy Inference)
# ---------------------------------------------------------
cmd_infer() {
    local TASK="$DEFAULT_TASK"
    local POLICY_TYPE="gr00tn1.5"
    local POLICY_HOST="localhost"
    local POLICY_PORT=5555
    local POLICY_TIMEOUT_MS=15000
    local POLICY_ACTION_HORIZON=16
    local POLICY_LANGUAGE_INSTRUCTION=""
    local POLICY_CHECKPOINT_PATH=""
    local STEP_HZ=60
    local EVAL_ROUNDS=0
    local USE_WEBRTC=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --task)                      TASK="$2"; shift 2 ;;
            --policy_type)               POLICY_TYPE="$2"; shift 2 ;;
            --policy_host)               POLICY_HOST="$2"; shift 2 ;;
            --policy_port)               POLICY_PORT="$2"; shift 2 ;;
            --policy_timeout_ms)         POLICY_TIMEOUT_MS="$2"; shift 2 ;;
            --policy_action_horizon)     POLICY_ACTION_HORIZON="$2"; shift 2 ;;
            --policy_language_instruction) POLICY_LANGUAGE_INSTRUCTION="$2"; shift 2 ;;
            --policy_checkpoint_path)    POLICY_CHECKPOINT_PATH="$2"; shift 2 ;;
            --step_hz)                   STEP_HZ="$2"; shift 2 ;;
            --eval_rounds)               EVAL_ROUNDS="$2"; shift 2 ;;
            --webrtc)                    USE_WEBRTC=true; shift ;;
            *)                           echo "Unknown parameter for infer: $1"; exit 1 ;;
        esac
    done

    local LIVESTREAM_PARAM=""
    if [ "$USE_WEBRTC" = true ]; then
        LIVESTREAM_PARAM="--livestream 2"
    fi

    echo "Starting policy inference..."
    echo "Task: $TASK"
    echo "Policy: $POLICY_TYPE @ $POLICY_HOST:$POLICY_PORT"

    python scripts/evaluation/policy_inference.py \
        --task="$TASK" \
        --policy_type="$POLICY_TYPE" \
        --policy_host="$POLICY_HOST" \
        --policy_port $POLICY_PORT \
        --policy_timeout_ms $POLICY_TIMEOUT_MS \
        --policy_action_horizon $POLICY_ACTION_HORIZON \
        --step_hz $STEP_HZ \
        --eval_rounds $EVAL_ROUNDS \
        $LIVESTREAM_PARAM \
        ${POLICY_LANGUAGE_INSTRUCTION:+--policy_language_instruction "$POLICY_LANGUAGE_INSTRUCTION"} \
        ${POLICY_CHECKPOINT_PATH:+--policy_checkpoint_path "$POLICY_CHECKPOINT_PATH"}
}

# ---------------------------------------------------------
# COMMAND: LIST (List environments)
# ---------------------------------------------------------
cmd_list() {
    python scripts/environments/list_envs.py
}

# ---------------------------------------------------------
# COMMAND: SYNC
# ---------------------------------------------------------
cmd_sync() {
    # Configuration paths
    local REMOTE_PATH="/root/DevSpace/IsaacLab-uv/logs/"
    local LOCAL_PATH="$HOME/DevSpace/IsaacLab-uv/logs/"

    echo "Starting sync from AutoDL..."

    if ! command -v sshpass &> /dev/null; then
        echo "Error: sshpass is not installed."
        exit 1
    fi

    # Ensure env vars are set
    if [ -z "$HOST" ] || [ -z "$PORT" ] || [ -z "$PASSWORD" ]; then
        echo "Error: HOST, PORT, or PASSWORD not set in .env"
        exit 1
    fi

    sshpass -p "$PASSWORD" rsync -avzP \
        -e "ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
        --exclude '*.tfevents*' \
        "root@$HOST:$REMOTE_PATH" "$LOCAL_PATH"

    echo "Sync finished."
}

# ---------------------------------------------------------
# MAIN DISPATCHER
# ---------------------------------------------------------
COMMAND="$1"
shift # Remove the command name from args, leaving the flags

case "$COMMAND" in
    play)
        cmd_play "$@"
        ;;
    replay)
        cmd_replay "$@"
        ;;
    infer)
        cmd_infer "$@"
        ;;
    list)
        cmd_list
        ;;
    sync)
        cmd_sync
        ;;
    *)
        show_help
        exit 1
        ;;
esac
