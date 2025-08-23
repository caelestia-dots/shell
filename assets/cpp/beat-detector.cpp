#include <algorithm>
#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>
#include <spa/param/props.h>
#include <aubio/aubio.h>
#include <memory>
#include <iostream>
#include <fstream>
#include <csignal>
#include <atomic>
#include <vector>
#include <cstring>
#include <chrono>
#include <iomanip>
#include <sstream>
#include <thread>
#include <cmath>

class EnhancedBeatDetector {
private:
    static constexpr uint32_t SAMPLE_RATE = 44100;
    static constexpr uint32_t CHANNELS = 1;
    
    // PipeWire objects
    pw_main_loop* main_loop_;
    pw_context* context_;
    pw_core* core_;
    pw_stream* stream_;
    
    // Aubio objects
    std::unique_ptr<aubio_tempo_t, decltype(&del_aubio_tempo)> tempo_;
    std::unique_ptr<fvec_t, decltype(&del_fvec)> input_buffer_;
    std::unique_ptr<fvec_t, decltype(&del_fvec)> output_buffer_;
    
    // Additional aubio objects for enhanced features
    std::unique_ptr<aubio_onset_t, decltype(&del_aubio_onset)> onset_;
    std::unique_ptr<aubio_pitch_t, decltype(&del_aubio_pitch)> pitch_;
    std::unique_ptr<fvec_t, decltype(&del_fvec)> pitch_buffer_;
    
    const uint32_t buf_size_;
    const uint32_t fft_size_;
    
    static std::atomic<bool> should_quit_;
    static EnhancedBeatDetector* instance_;
    
    // Enhanced features
    std::ofstream log_file_;
    bool enable_logging_;
    bool enable_performance_stats_;
    bool enable_pitch_detection_;
    bool enable_visual_feedback_;
    
    // Performance tracking
    std::chrono::high_resolution_clock::time_point last_process_time_;
    std::vector<double> process_times_;
    uint64_t total_beats_;
    uint64_t total_onsets_;
    std::chrono::steady_clock::time_point start_time_;
    
    // Beat analysis
    std::vector<float> recent_bpms_;
    static constexpr size_t BPM_HISTORY_SIZE = 10;
    float last_bpm_;
    std::chrono::steady_clock::time_point last_beat_time_;
    
    // Useless Visual feedback
    std::string generate_beat_visual(float bpm, bool is_beat) {
        if (!enable_visual_feedback_) return "";
        
        std::stringstream ss;
        if (is_beat) {
            // Useless Animated beat indicator based on BPM intensity
            int intensity = static_cast<int>(std::min(bpm / 20.0f, 10.0f));
            ss << "\r ";
            for (int i = 0; i < intensity; ++i) ss << "█";
            for (int i = intensity; i < 10; ++i) ss << "░";
            ss << " BPM: " << std::fixed << std::setprecision(1) << bpm;
            ss << " | Avg: " << get_average_bpm();
        }
        return ss.str();
    }

public:
    explicit EnhancedBeatDetector(uint32_t buf_size = 512, 
                                 bool enable_logging = true,
                                 bool enable_performance_stats = true,
                                 bool enable_pitch_detection = false,
                                 bool enable_visual_feedback = true) 
        : main_loop_(nullptr)
        , context_(nullptr)
        , core_(nullptr)
        , stream_(nullptr)
        , tempo_(nullptr, &del_aubio_tempo)
        , input_buffer_(nullptr, &del_fvec)
        , output_buffer_(nullptr, &del_fvec)
        , onset_(nullptr, &del_aubio_onset)
        , pitch_(nullptr, &del_aubio_pitch)
        , pitch_buffer_(nullptr, &del_fvec)
        , buf_size_(buf_size)
        , fft_size_(buf_size * 2)
        , enable_logging_(enable_logging)
        , enable_performance_stats_(enable_performance_stats)
        , enable_pitch_detection_(enable_pitch_detection)
        , enable_visual_feedback_(enable_visual_feedback)
        , total_beats_(0)
        , total_onsets_(0)
        , last_bpm_(0.0f)
    {
        instance_ = this;
        recent_bpms_.reserve(BPM_HISTORY_SIZE);
        if (enable_performance_stats_) {
            process_times_.reserve(1000); // Reserve space for performance data
        }
        initialize();
    }
    
    ~EnhancedBeatDetector() {
        print_final_stats();
        cleanup();
        instance_ = nullptr;
    }
    
    // Delete copy constructor and assignment operator
    EnhancedBeatDetector(const EnhancedBeatDetector&) = delete;
    EnhancedBeatDetector& operator=(const EnhancedBeatDetector&) = delete;
    
    bool initialize() {
        start_time_ = std::chrono::steady_clock::now();
        
        // Useless Initialize logging (actually useful)
        if (enable_logging_) {
            auto now = std::chrono::system_clock::now();
            auto time_t = std::chrono::system_clock::to_time_t(now);
            std::stringstream filename;
            filename << "beat_log_" << std::put_time(std::localtime(&time_t), "%Y%m%d_%H%M%S") << ".txt";
            log_file_.open(filename.str());
            if (log_file_.is_open()) {
                log_file_ << "# Beat Detection Log - " << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S") << "\n";
                log_file_ << "# Timestamp,BPM,Onset,Pitch(Hz),ProcessTime(ms)\n";
                std::cout << " Logging to: " << filename.str() << std::endl;
            }
        }
        
        // Initialize PipeWire
        pw_init(nullptr, nullptr);
        
        main_loop_ = pw_main_loop_new(nullptr);
        if (!main_loop_) {
            std::cerr << " Failed to create main loop" << std::endl;
            return false;
        }
        
        context_ = pw_context_new(pw_main_loop_get_loop(main_loop_), nullptr, 0);
        if (!context_) {
            std::cerr << " Failed to create context" << std::endl;
            return false;
        }
        
        core_ = pw_context_connect(context_, nullptr, 0);
        if (!core_) {
            std::cerr << " Failed to connect to PipeWire" << std::endl;
            return false;
        }
        
        // Initialize Aubio objects
        tempo_.reset(new_aubio_tempo("default", fft_size_, buf_size_, SAMPLE_RATE));
        if (!tempo_) {
            std::cerr << " Failed to create aubio tempo detector" << std::endl;
            return false;
        }
        
        input_buffer_.reset(new_fvec(buf_size_));
        output_buffer_.reset(new_fvec(1));
        
        if (!input_buffer_ || !output_buffer_) {
            std::cerr << " Failed to create aubio buffers" << std::endl;
            return false;
        }
        
        // Initialize onset detection
        onset_.reset(new_aubio_onset("default", fft_size_, buf_size_, SAMPLE_RATE));
        if (!onset_) {
            std::cerr << " Failed to create aubio onset detector" << std::endl;
            return false;
        }
        
        // Initialize pitch detection if enabled
        if (enable_pitch_detection_) {
            pitch_.reset(new_aubio_pitch("default", fft_size_, buf_size_, SAMPLE_RATE));
            pitch_buffer_.reset(new_fvec(1));
            if (!pitch_ || !pitch_buffer_) {
                std::cerr << " Failed to create aubio pitch detector" << std::endl;
                return false;
            }
            aubio_pitch_set_unit(pitch_.get(), "Hz");
        }
        
        return setup_stream();
    }
    
    void run() {
        if (!main_loop_) return;
        
        print_startup_info();
        pw_main_loop_run(main_loop_);
    }
    
    void stop() {
        should_quit_ = true;
        if (main_loop_) {
            pw_main_loop_quit(main_loop_);
        }
    }
    
    static void signal_handler(int sig) {
        if (instance_) {
            std::cout << "\n Received signal " << sig << ", stopping gracefullllly..." << std::endl;
            instance_->stop();
        }
    }

private:
    void print_startup_info() {
        std::cout << "\n󰝚  Beat Detector Started!" << std::endl;
        std::cout << "   Buffer size: " << buf_size_ << " samples" << std::endl;
        std::cout << "   Sample rate: " << SAMPLE_RATE << " Hz" << std::endl;
        std::cout << "   Features enabled:" << std::endl;
        std::cout << "    Logging: " << (enable_logging_ ? " " : "") << std::endl;
        std::cout << "     Performance stats: " << (enable_performance_stats_ ? " " : "") << std::endl;
        std::cout << "   󰗅  Pitch detection: " << (enable_pitch_detection_ ? " " : "") << std::endl;
        std::cout << "\n Listening for beats... Press Ctrl+C to stop.\n" << std::endl;
    }
    
    void print_final_stats() {
        if (!enable_performance_stats_) return;
        
        auto end_time = std::chrono::steady_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::seconds>(end_time - start_time_);
        
        std::cout << "\n  Final Statistics:" << std::endl;
        std::cout << "   󱎫  Total runtime: " << duration.count() << " seconds" << std::endl;
        std::cout << "    Total beats detected: " << total_beats_ << std::endl;
        std::cout << "    Total onsets detected: " << total_onsets_ << std::endl;
        
        if (!process_times_.empty()) {
            double avg_time = 0;
            for (double t : process_times_) avg_time += t;
            avg_time /= process_times_.size();
            
            auto max_time = *std::max_element(process_times_.begin(), process_times_.end());
            auto min_time = *std::min_element(process_times_.begin(), process_times_.end());
            
            std::cout << "   ⚡ Average processing time: " << std::fixed << std::setprecision(3) 
                      << avg_time << " ms" << std::endl;
            std::cout << "   📈 Max processing time: " << max_time << " ms" << std::endl;
            std::cout << "   📉 Min processing time: " << min_time << " ms" << std::endl;
        }
        
        if (!recent_bpms_.empty()) {
            std::cout << "   󰝚 Final average BPM: " << get_average_bpm() << std::endl;
        }
    }
    
    float get_average_bpm() const {
        if (recent_bpms_.empty()) return 0.0f;
        float sum = 0;
        for (float bpm : recent_bpms_) sum += bpm;
        return sum / recent_bpms_.size();
    }
    
    bool setup_stream() {
        // Stream events
        static const pw_stream_events stream_events = {
            .version = PW_VERSION_STREAM_EVENTS,
            .destroy = nullptr,
            .state_changed = on_state_changed,
            .control_info = nullptr,
            .io_changed = nullptr,
            .param_changed = nullptr,
            .add_buffer = nullptr,
            .remove_buffer = nullptr,
            .process = on_process,
            .drained = nullptr,
            .command = nullptr,
            .trigger_done = nullptr,
        };
        
        stream_ = pw_stream_new_simple(
            pw_main_loop_get_loop(main_loop_),
            "enhanced-beat-detector",
            pw_properties_new(
                PW_KEY_MEDIA_TYPE, "Audio",
                PW_KEY_MEDIA_CATEGORY, "Capture",
                PW_KEY_MEDIA_ROLE, "Music",
                nullptr
            ),
            &stream_events,
            this
        );
        
        if (!stream_) {
            std::cerr << " Failed to create stream" << std::endl;
            return false;
        }
        
        // Audio format parameters
        uint8_t buffer[1024];
        spa_pod_builder pod_builder = SPA_POD_BUILDER_INIT(buffer, sizeof(buffer));
        
        struct spa_audio_info_raw audio_info = {};
        audio_info.format = SPA_AUDIO_FORMAT_F32_LE;
        audio_info.channels = CHANNELS;
        audio_info.rate = SAMPLE_RATE;
        audio_info.flags = 0;
        
        const spa_pod* params[1];
        params[0] = spa_format_audio_raw_build(&pod_builder, SPA_PARAM_EnumFormat, &audio_info);
        
        if (pw_stream_connect(stream_,
                             PW_DIRECTION_INPUT,
                             PW_ID_ANY,
                             static_cast<pw_stream_flags>(
                                 PW_STREAM_FLAG_AUTOCONNECT |
                                 PW_STREAM_FLAG_MAP_BUFFERS |
                                 PW_STREAM_FLAG_RT_PROCESS),
                             params, 1) < 0) {
            std::cerr << " Failed to connect stream" << std::endl;
            return false;
        }
        
        return true;
    }
    
    static void on_state_changed(void* userdata, enum pw_stream_state /* old_state */, 
                                enum pw_stream_state state, const char* error) {
        auto* detector = static_cast<EnhancedBeatDetector*>(userdata);
        
        const char* state_emoji = "󰑓 ";
        switch (state) {
            case PW_STREAM_STATE_CONNECTING: state_emoji = "󰄙 "; break;
            case PW_STREAM_STATE_PAUSED: state_emoji = ""; break;
            case PW_STREAM_STATE_STREAMING: state_emoji = "󰝚 "; break;
            case PW_STREAM_STATE_ERROR: state_emoji = ""; break;
            case PW_STREAM_STATE_UNCONNECTED: state_emoji = " "; break;
        }
        
        std::cout << state_emoji << " Stream state: " << pw_stream_state_as_string(state) << std::endl;
        
        if (state == PW_STREAM_STATE_ERROR) {
            std::cerr << " Stream error: " << (error ? error : "unknown") << std::endl;
            detector->stop();
        }
    }
    
    static void on_process(void* userdata) {
        auto* detector = static_cast<EnhancedBeatDetector*>(userdata);
        detector->process_audio();
    }
    
    void process_audio() {
        if (should_quit_) return;
        
        auto process_start = std::chrono::high_resolution_clock::now();
        
        pw_buffer* buffer = pw_stream_dequeue_buffer(stream_);
        if (!buffer) return;
        
        spa_buffer* spa_buf = buffer->buffer;
        if (!spa_buf->datas[0].data) {
            pw_stream_queue_buffer(stream_, buffer);
            return;
        }
        
        const float* audio_data = static_cast<const float*>(spa_buf->datas[0].data);
        const uint32_t n_samples = spa_buf->datas[0].chunk->size / sizeof(float);
        
        // Process in chunks
        for (uint32_t offset = 0; offset + buf_size_ <= n_samples; offset += buf_size_) {
            std::memcpy(input_buffer_->data, audio_data + offset, buf_size_ * sizeof(float));
            
            // Beat detection
            aubio_tempo_do(tempo_.get(), input_buffer_.get(), output_buffer_.get());
            bool is_beat = output_buffer_->data[0] != 0.0f;
            
            // Onset detection
            aubio_onset_do(onset_.get(), input_buffer_.get(), output_buffer_.get());
            bool is_onset = output_buffer_->data[0] != 0.0f;
            
            float pitch_hz = 0.0f;
            if (enable_pitch_detection_) {
                aubio_pitch_do(pitch_.get(), input_buffer_.get(), pitch_buffer_.get());
                pitch_hz = pitch_buffer_->data[0];
            }
            
            if (is_beat) {
                total_beats_++;
                last_bpm_ = aubio_tempo_get_bpm(tempo_.get());
                last_beat_time_ = std::chrono::steady_clock::now();
                
                // Update BPM history
                recent_bpms_.push_back(last_bpm_);
                if (recent_bpms_.size() > BPM_HISTORY_SIZE) {
                    recent_bpms_.erase(recent_bpms_.begin());
                }
                
                // Visual feedback
                if (enable_visual_feedback_) {
                    std::cout << generate_beat_visual(last_bpm_, true) << std::flush;
                } else {
                    std::cout << " BPM: " << std::fixed << std::setprecision(1) << last_bpm_ << std::endl;
                }
            }
            
            if (is_onset) {
                total_onsets_++;
            }
            
            // Logging
            if (enable_logging_ && log_file_.is_open() && (is_beat || is_onset)) {
                auto now = std::chrono::system_clock::now();
                auto time_t = std::chrono::system_clock::to_time_t(now);
                auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                    now.time_since_epoch()) % 1000;
                
                log_file_ << std::put_time(std::localtime(&time_t), "%H:%M:%S") 
                         << "." << std::setfill('0') << std::setw(3) << ms.count() << ","
                         << (is_beat ? last_bpm_ : 0) << ","
                         << (is_onset ? 1 : 0) << ","
                         << pitch_hz << ",";
            }
        }
        
        pw_stream_queue_buffer(stream_, buffer);
        
        // Performance tracking
        if (enable_performance_stats_) {
            auto process_end = std::chrono::high_resolution_clock::now();
            auto process_time = std::chrono::duration<double, std::milli>(process_end - process_start).count();
            
            if (log_file_.is_open() && (total_beats_ > 0 || total_onsets_ > 0)) {
                log_file_ << std::fixed << std::setprecision(3) << process_time << "\n";
            }
            
            if (process_times_.size() < 1000) {
                process_times_.push_back(process_time);
            }
        }
    }
    
    void cleanup() {
        if (log_file_.is_open()) {
            log_file_.close();
        }
        
        if (stream_) {
            pw_stream_destroy(stream_);
            stream_ = nullptr;
        }
        
        if (core_) {
            pw_core_disconnect(core_);
            core_ = nullptr;
        }
        
        if (context_) {
            pw_context_destroy(context_);
            context_ = nullptr;
        }
        
        if (main_loop_) {
            pw_main_loop_destroy(main_loop_);
            main_loop_ = nullptr;
        }
        
        tempo_.reset();
        input_buffer_.reset();
        output_buffer_.reset();
        onset_.reset();
        pitch_.reset();
        pitch_buffer_.reset();
        
        pw_deinit();
        
        std::cout << "\n Cleanup complete - All resources freed!" << std::endl;
    }
};

// Static member definitions
std::atomic<bool> EnhancedBeatDetector::should_quit_{false};
EnhancedBeatDetector* EnhancedBeatDetector::instance_{nullptr};

void print_usage() {
    std::cout << " Beat Detector Usage:" << std::endl;
    std::cout << "  ./beat_detector [buffer_size] [options]" << std::endl;
    std::cout << "\nOptions:" << std::endl;
    std::cout << "  --no-log          Disable logging to file" << std::endl;
    std::cout << "  --no-stats        Disable performance statistics" << std::endl;
    std::cout << "  --pitch           Enable pitch detection" << std::endl;
    std::cout << "  --no-visual       Disable visual feedback" << std::endl;
    std::cout << "  --help            Show this help" << std::endl;
    std::cout << "\nExamples:" << std::endl;
    std::cout << "  ./beat_detector                    # Default settings" << std::endl;
    std::cout << "  ./beat_detector 256 --pitch       # Smaller buffer with pitch detection" << std::endl;
    std::cout << "  ./beat_detector 1024 --no-visual  # Larger buffer, no visual feedback" << std::endl;
}

int main(int argc, char* argv[]) {
    // Parse command line arguments
    uint32_t buffer_size = 512;
    bool enable_logging = true;
    bool enable_performance_stats = true;
    bool enable_pitch_detection = false;
    bool enable_visual_feedback = true;
    
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        
        if (arg == "--help" || arg == "-h") {
            print_usage();
            return 0;
        } else if (arg == "--no-log") {
            enable_logging = false;
        } else if (arg == "--no-stats") {
            enable_performance_stats = false;
        } else if (arg == "--pitch") {
            enable_pitch_detection = true;
        } else if (arg == "--no-visual") {
            enable_visual_feedback = false;
        } else if (arg[0] != '-') {
            // Assume it's a buffer size
            try {
                buffer_size = std::stoul(arg);
                if (buffer_size < 64 || buffer_size > 8192) {
                    std::cerr << " Buffer size must be between 64 and 8192" << std::endl;
                    return 1;
                }
            } catch (...) {
                std::cerr << " Invalid buffer size: " << arg << std::endl;
                return 1;
            }
        } else {
            std::cerr << " Unknown option: " << arg << std::endl;
            print_usage();
            return 1;
        }
    }
    
    // Set up signal handling
    std::signal(SIGINT, EnhancedBeatDetector::signal_handler);
    std::signal(SIGTERM, EnhancedBeatDetector::signal_handler);
    
    try {
        EnhancedBeatDetector detector(buffer_size, enable_logging, enable_performance_stats,
                                     enable_pitch_detection, enable_visual_feedback);
        detector.run();
    } catch (const std::exception& e) {
        std::cerr << " Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}

/*
 * Compilation command:
 * g++ -std=c++17 -O3 -Wall -Wextra -I/usr/include/pipewire-0.3 -I/usr/include/spa-0.2 -I/usr/include/aubio \
 *     -o beat_detector beat_detector.cpp -lpipewire-0.3 -laubio -pthread
 */
