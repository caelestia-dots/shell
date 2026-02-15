#pragma once

#include "audioprovider.hpp"
#include <cava/cavacore.h>
#include <fftw3.h>
#include <qqmlintegration.h>

// Full definition of cava_plan to fix incomplete type errors and ensure ABI compatibility.
// This matches the definition in the upstream cavacore.h (v0.10+).
struct cava_plan {
    int FFTbassbufferSize;
    int FFTbufferSize;
    int number_of_bars;
    int audio_channels;
    int input_buffer_size;
    int rate;
    int bass_cut_off_bar;
    int sens_init;
    int autosens;
    int frame_skip;
    int status;
    char error_message[1024];

    double sens;
    double framerate;
    double noise_reduction;

    fftw_plan p_bass_l, p_bass_r;
    fftw_plan p_l, p_r;

    fftw_complex *out_bass_l, *out_bass_r;
    fftw_complex *out_l, *out_r;

    double *bass_multiplier;
    double *multiplier;

    double *in_bass_r_raw, *in_bass_l_raw;
    double *in_r_raw, *in_l_raw;
    double *in_bass_r, *in_bass_l;
    double *in_r, *in_l;
    double *prev_cava_out, *cava_mem;
    double *input_buffer, *cava_peak;

    double *eq;

    float *cut_off_frequency;
    int *FFTbuffer_lower_cut_off;
    int *FFTbuffer_upper_cut_off;
    double *cava_fall;
};

namespace caelestia::services {

class CavaProcessor : public AudioProcessor {
    Q_OBJECT

public:
    explicit CavaProcessor(QObject* parent = nullptr);
    ~CavaProcessor();

    void setBars(int bars);

signals:
    void valuesChanged(QVector<double> values);

protected:
    void process() override;

private:
    struct cava_plan* m_plan;
    double* m_in;
    double* m_out;

    int m_bars;
    QVector<double> m_values;

    void reload();
    void initCava();
    void cleanup();
};

class CavaProvider : public AudioProvider {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int bars READ bars WRITE setBars NOTIFY barsChanged)

    Q_PROPERTY(QVector<double> values READ values NOTIFY valuesChanged)

public:
    explicit CavaProvider(QObject* parent = nullptr);

    [[nodiscard]] int bars() const;
    void setBars(int bars);

    [[nodiscard]] QVector<double> values() const;

signals:
    void barsChanged();
    void valuesChanged();

private:
    int m_bars;
    QVector<double> m_values;

    void updateValues(QVector<double> values);
};

} // namespace caelestia::services
