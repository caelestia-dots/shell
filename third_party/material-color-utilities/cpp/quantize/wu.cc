/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "cpp/quantize/wu.h"

#include <stdlib.h>

#include <cassert>
#include <cstdint>
#include <cstdio>
#include <vector>

#include "cpp/utils/utils.h"

namespace material_color_utilities {

struct Box {
  int r0 = 0;
  int r1 = 0;
  int g0 = 0;
  int g1 = 0;
  int b0 = 0;
  int b1 = 0;
  int vol = 0;
};

enum class Direction {
  kRed,
  kGreen,
  kBlue,
};

constexpr int kIndexBits = 5;
constexpr int kIndexCount = ((1 << kIndexBits) + 1);
constexpr int kTotalSize = (kIndexCount * kIndexCount * kIndexCount);
constexpr int kMaxColors = 256;

using IntArray = std::vector<int64_t>;
using DoubleArray = std::vector<double>;

int GetIndex(int r, int g, int b) {
  return (r << (kIndexBits * 2)) + (r << (kIndexBits + 1)) + (g << kIndexBits) +
         r + g + b;
}

void ConstructHistogram(const std::vector<Argb>& pixels, IntArray& weights,
                        IntArray& m_r, IntArray& m_g, IntArray& m_b,
                        DoubleArray& moments) {
  for (size_t i = 0; i < pixels.size(); i++) {
    Argb pixel = pixels[i];
    int red = RedFromInt(pixel);
    int green = GreenFromInt(pixel);
    int blue = BlueFromInt(pixel);

    int bits_to_remove = 8 - kIndexBits;
    int index_r = (red >> bits_to_remove) + 1;
    int index_g = (green >> bits_to_remove) + 1;
    int index_b = (blue >> bits_to_remove) + 1;
    int index = GetIndex(index_r, index_g, index_b);

    weights[index]++;
    m_r[index] += red;
    m_g[index] += green;
    m_b[index] += blue;
    moments[index] += (red * red) + (green * green) + (blue * blue);
  }
}

void ComputeMoments(IntArray& weights, IntArray& m_r, IntArray& m_g,
                    IntArray& m_b, DoubleArray& moments) {
  for (int r = 1; r < kIndexCount; r++) {
    int64_t area[kIndexCount] = {};
    int64_t area_r[kIndexCount] = {};
    int64_t area_g[kIndexCount] = {};
    int64_t area_b[kIndexCount] = {};
    double area_2[kIndexCount] = {};
    for (int g = 1; g < kIndexCount; g++) {
      int64_t line = 0;
      int64_t line_r = 0;
      int64_t line_g = 0;
      int64_t line_b = 0;
      double line_2 = 0.0;
      for (int b = 1; b < kIndexCount; b++) {
        int index = GetIndex(r, g, b);
        line += weights[index];
        line_r += m_r[index];
        line_g += m_g[index];
        line_b += m_b[index];
        line_2 += moments[index];

        area[b] += line;
        area_r[b] += line_r;
        area_g[b] += line_g;
        area_b[b] += line_b;
        area_2[b] += line_2;

        int previous_index = GetIndex(r - 1, g, b);
        weights[index] = weights[previous_index] + area[b];
        m_r[index] = m_r[previous_index] + area_r[b];
        m_g[index] = m_g[previous_index] + area_g[b];
        m_b[index] = m_b[previous_index] + area_b[b];
        moments[index] = moments[previous_index] + area_2[b];
      }
    }
  }
}

int64_t Top(const Box& cube, const Direction direction, const int position,
            const IntArray& moment) {
  if (direction == Direction::kRed) {
    return (moment[GetIndex(position, cube.g1, cube.b1)] -
            moment[GetIndex(position, cube.g1, cube.b0)] -
            moment[GetIndex(position, cube.g0, cube.b1)] +
            moment[GetIndex(position, cube.g0, cube.b0)]);
  } else if (direction == Direction::kGreen) {
    return (moment[GetIndex(cube.r1, position, cube.b1)] -
            moment[GetIndex(cube.r1, position, cube.b0)] -
            moment[GetIndex(cube.r0, position, cube.b1)] +
            moment[GetIndex(cube.r0, position, cube.b0)]);
  } else {
    return (moment[GetIndex(cube.r1, cube.g1, position)] -
            moment[GetIndex(cube.r1, cube.g0, position)] -
            moment[GetIndex(cube.r0, cube.g1, position)] +
            moment[GetIndex(cube.r0, cube.g0, position)]);
  }
}

int64_t Bottom(const Box& cube, const Direction direction,
               const IntArray& moment) {
  if (direction == Direction::kRed) {
    return (-moment[GetIndex(cube.r0, cube.g1, cube.b1)] +
            moment[GetIndex(cube.r0, cube.g1, cube.b0)] +
            moment[GetIndex(cube.r0, cube.g0, cube.b1)] -
            moment[GetIndex(cube.r0, cube.g0, cube.b0)]);
  } else if (direction == Direction::kGreen) {
    return (-moment[GetIndex(cube.r1, cube.g0, cube.b1)] +
            moment[GetIndex(cube.r1, cube.g0, cube.b0)] +
            moment[GetIndex(cube.r0, cube.g0, cube.b1)] -
            moment[GetIndex(cube.r0, cube.g0, cube.b0)]);
  } else {
    return (-moment[GetIndex(cube.r1, cube.g1, cube.b0)] +
            moment[GetIndex(cube.r1, cube.g0, cube.b0)] +
            moment[GetIndex(cube.r0, cube.g1, cube.b0)] -
            moment[GetIndex(cube.r0, cube.g0, cube.b0)]);
  }
}

int64_t Vol(const Box& cube, const IntArray& moment) {
  return (moment[GetIndex(cube.r1, cube.g1, cube.b1)] -
          moment[GetIndex(cube.r1, cube.g1, cube.b0)] -
          moment[GetIndex(cube.r1, cube.g0, cube.b1)] +
          moment[GetIndex(cube.r1, cube.g0, cube.b0)] -
          moment[GetIndex(cube.r0, cube.g1, cube.b1)] +
          moment[GetIndex(cube.r0, cube.g1, cube.b0)] +
          moment[GetIndex(cube.r0, cube.g0, cube.b1)] -
          moment[GetIndex(cube.r0, cube.g0, cube.b0)]);
}

double Variance(const Box& cube, const IntArray& weights, const IntArray& m_r,
                const IntArray& m_g, const IntArray& m_b,
                const DoubleArray& moments) {
  double dr = Vol(cube, m_r);
  double dg = Vol(cube, m_g);
  double db = Vol(cube, m_b);
  double xx = moments[GetIndex(cube.r1, cube.g1, cube.b1)] -
              moments[GetIndex(cube.r1, cube.g1, cube.b0)] -
              moments[GetIndex(cube.r1, cube.g0, cube.b1)] +
              moments[GetIndex(cube.r1, cube.g0, cube.b0)] -
              moments[GetIndex(cube.r0, cube.g1, cube.b1)] +
              moments[GetIndex(cube.r0, cube.g1, cube.b0)] +
              moments[GetIndex(cube.r0, cube.g0, cube.b1)] -
              moments[GetIndex(cube.r0, cube.g0, cube.b0)];
  double hypotenuse = dr * dr + dg * dg + db * db;
  double volume = Vol(cube, weights);
  return xx - hypotenuse / volume;
}

double Maximize(const Box& cube, const Direction direction, const int first,
                const int last, int* cut, const int64_t whole_w,
                const int64_t whole_r, const int64_t whole_g,
                const int64_t whole_b, const IntArray& weights,
                const IntArray& m_r, const IntArray& m_g, const IntArray& m_b) {
  int64_t bottom_r = Bottom(cube, direction, m_r);
  int64_t bottom_g = Bottom(cube, direction, m_g);
  int64_t bottom_b = Bottom(cube, direction, m_b);
  int64_t bottom_w = Bottom(cube, direction, weights);

  double max = 0.0;
  *cut = -1;

  int64_t half_r, half_g, half_b, half_w;
  for (int i = first; i < last; i++) {
    half_r = bottom_r + Top(cube, direction, i, m_r);
    half_g = bottom_g + Top(cube, direction, i, m_g);
    half_b = bottom_b + Top(cube, direction, i, m_b);
    half_w = bottom_w + Top(cube, direction, i, weights);
    if (half_w == 0) {
      continue;
    }

    double temp = (static_cast<double>(half_r) * half_r +
                   static_cast<double>(half_g) * half_g +
                   static_cast<double>(half_b) * half_b) /
                  static_cast<double>(half_w);

    half_r = whole_r - half_r;
    half_g = whole_g - half_g;
    half_b = whole_b - half_b;
    half_w = whole_w - half_w;
    if (half_w == 0) {
      continue;
    }
    temp += (static_cast<double>(half_r) * half_r +
             static_cast<double>(half_g) * half_g +
             static_cast<double>(half_b) * half_b) /
            static_cast<double>(half_w);

    if (temp > max) {
      max = temp;
      *cut = i;
    }
  }
  return max;
}

bool Cut(Box& box1, Box& box2, const IntArray& weights, const IntArray& m_r,
         const IntArray& m_g, const IntArray& m_b) {
  int64_t whole_r = Vol(box1, m_r);
  int64_t whole_g = Vol(box1, m_g);
  int64_t whole_b = Vol(box1, m_b);
  int64_t whole_w = Vol(box1, weights);

  int cut_r, cut_g, cut_b;
  double max_r =
      Maximize(box1, Direction::kRed, box1.r0 + 1, box1.r1, &cut_r, whole_w,
               whole_r, whole_g, whole_b, weights, m_r, m_g, m_b);
  double max_g =
      Maximize(box1, Direction::kGreen, box1.g0 + 1, box1.g1, &cut_g, whole_w,
               whole_r, whole_g, whole_b, weights, m_r, m_g, m_b);
  double max_b =
      Maximize(box1, Direction::kBlue, box1.b0 + 1, box1.b1, &cut_b, whole_w,
               whole_r, whole_g, whole_b, weights, m_r, m_g, m_b);

  Direction direction;
  if (max_r >= max_g && max_r >= max_b) {
    direction = Direction::kRed;
    if (cut_r < 0) {
      return false;
    }
  } else if (max_g >= max_r && max_g >= max_b) {
    direction = Direction::kGreen;
  } else {
    direction = Direction::kBlue;
  }

  box2.r1 = box1.r1;
  box2.g1 = box1.g1;
  box2.b1 = box1.b1;

  if (direction == Direction::kRed) {
    box2.r0 = box1.r1 = cut_r;
    box2.g0 = box1.g0;
    box2.b0 = box1.b0;
  } else if (direction == Direction::kGreen) {
    box2.r0 = box1.r0;
    box2.g0 = box1.g1 = cut_g;
    box2.b0 = box1.b0;
  } else {
    box2.r0 = box1.r0;
    box2.g0 = box1.g0;
    box2.b0 = box1.b1 = cut_b;
  }

  box1.vol = (box1.r1 - box1.r0) * (box1.g1 - box1.g0) * (box1.b1 - box1.b0);
  box2.vol = (box2.r1 - box2.r0) * (box2.g1 - box2.g0) * (box2.b1 - box2.b0);
  return true;
}

std::vector<Argb> QuantizeWu(const std::vector<Argb>& pixels,
                             uint16_t max_colors) {
  if (max_colors <= 0 || max_colors > 256 || pixels.empty()) {
    return std::vector<Argb>();
  }

  IntArray weights(kTotalSize, 0);
  IntArray moments_red(kTotalSize, 0);
  IntArray moments_green(kTotalSize, 0);
  IntArray moments_blue(kTotalSize, 0);
  DoubleArray moments(kTotalSize, 0.0);
  ConstructHistogram(pixels, weights, moments_red, moments_green, moments_blue,
                     moments);
  ComputeMoments(weights, moments_red, moments_green, moments_blue, moments);

  std::vector<Box> cubes(kMaxColors);
  cubes[0].r0 = cubes[0].g0 = cubes[0].b0 = 0;
  cubes[0].r1 = cubes[0].g1 = cubes[0].b1 = kIndexCount - 1;

  std::vector<double> volume_variance(kMaxColors);
  int next = 0;
  for (int i = 1; i < max_colors; ++i) {
    if (Cut(cubes[next], cubes[i], weights, moments_red, moments_green,
            moments_blue)) {
      volume_variance[next] =
          cubes[next].vol > 1 ? Variance(cubes[next], weights, moments_red,
                                         moments_green, moments_blue, moments)
                              : 0.0;
      volume_variance[i] = cubes[i].vol > 1
                               ? Variance(cubes[i], weights, moments_red,
                                          moments_green, moments_blue, moments)
                               : 0.0;
    } else {
      volume_variance[next] = 0.0;
      i--;
    }

    next = 0;
    double temp = volume_variance[0];
    for (int j = 1; j <= i; j++) {
      if (volume_variance[j] > temp) {
        temp = volume_variance[j];
        next = j;
      }
    }
    if (temp <= 0.0) {
      max_colors = i + 1;
      break;
    }
  }

  std::vector<Argb> out_colors;
  for (int i = 0; i < max_colors; ++i) {
    int64_t weight = Vol(cubes[i], weights);
    if (weight > 0) {
      int32_t red = Vol(cubes[i], moments_red) / weight;
      int32_t green = Vol(cubes[i], moments_green) / weight;
      int32_t blue = Vol(cubes[i], moments_blue) / weight;
      uint32_t argb = ArgbFromRgb(red, green, blue);
      out_colors.push_back(argb);
    }
  }

  return out_colors;
}
}  // namespace material_color_utilities
