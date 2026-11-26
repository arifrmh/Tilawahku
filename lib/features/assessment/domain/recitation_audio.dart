import 'dart:typed_data';

const int asrSampleRate = 16000;

/// Jumlah sampel 16 kHz terendah yang boleh diserahkan ke engine pengenalan.
///
/// Model Zipformer CTC rilis `int8-88f9df29` menurunkan frame dengan dua conv
/// `kernel_shape=[3,3]`, `strides=[2,2]`, `pads=[0,0,0,0]` (dibaca langsung dari
/// graph ONNX), jadi ia baru punya output setelah 7 frame fbank; satu frame
/// = 160 sampel (frame shift 10 ms). Di bawah itu ONNX Runtime tidak
/// menghasilkan transkrip melainkan gagal di dalam graph dengan
/// `Invalid input shape`.
///
/// Lantai terukur: 1039 sampel gagal, 1040 sampel berhasil, pada 961 titik
/// input (lihat `asr-spike/probe_min_frames.py` dan
/// `probe_min_frames_analysis.json`). Ambang diambil pada 10 frame — tiga frame
/// di atas lantai — supaya build runtime lain tidak bisa jatuh ke sisi gagal,
/// dan tetap jauh di bawah potongan bacaan nyata terpendek.
const int asrMinimumSamples = 1600;

class RecitationAudio {
  const RecitationAudio(this.samples);

  factory RecitationAudio.fromPcm16(Uint8List bytes) {
    final aligned = bytes.lengthInBytes - bytes.lengthInBytes % 2;
    final data = ByteData.sublistView(bytes, 0, aligned);
    final samples = Float32List(aligned ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return RecitationAudio(samples);
  }

  final Float32List samples;

  int get sampleRate => asrSampleRate;

  double get durationSeconds => samples.length / asrSampleRate;

  /// False untuk audio yang pasti ditolak engine; rekaman seperti ini tidak
  /// pernah dikirim ke runtime.
  bool get meetsAsrMinimum => samples.length >= asrMinimumSamples;

  /// Mengemas ulang sampel mono 16 kHz menjadi berkas WAV PCM 16-bit standar
  /// untuk diputar ulang di perangkat.
  Uint8List toWavBytes() {
    final dataLength = samples.length * 2;
    final bytes = Uint8List(44 + dataLength);
    final header = ByteData.sublistView(bytes);
    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes[offset + i] = value.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, asrSampleRate, Endian.little);
    header.setUint32(28, asrSampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      final value = (samples[i] * 32768.0).round().clamp(-32768, 32767);
      header.setInt16(44 + i * 2, value, Endian.little);
    }
    return bytes;
  }
}
