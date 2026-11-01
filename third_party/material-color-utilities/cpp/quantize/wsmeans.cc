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

#include "cpp/quantize/wsmeans.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <map>
#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include <unordered_map>
#include "cpp/quantize/lab.h"

constexpr int kMaxIterations = 100;
constexpr double kMinDeltaE = 3.0;

namespace material_color_utilities {

struct Swatch {
  Argb argb = 0;
  int population = 0;

  bool operator<(const Swatch& b) const { return population > b.population; }
};

struct DistanceToIndex {
  double distance = 0.0;
  int index = 0;

  bool operator<(const DistanceToIndex& a) const {
    return distance < a.distance;
  }
};

QuantizerResult QuantizeWsmeans(const std::vector<Argb>& input_pixels,
                                const std::vector<Argb>& starting_clusters,
                                uint16_t max_colors) {
  if (max_colors == 0 || input_pixels.empty()) {
    return QuantizerResult();
  }

  if (max_colors > 256) {
    // If colors is outside the range, just set it the max.
    max_colors = 256;
  }

  uint32_t pixel_count = input_pixels.size();
  std::unordered_map<Argb, int> pixel_to_count;
  std::vector<uint32_t> pixels;
  pixels.reserve(pixel_count);
  std::vector<Lab> points;
  points.reserve(pixel_count);
  for (Argb pixel : input_pixels) {
    // tested over 1000 runs with 128 colors, 12544 (112 x 112)
    // std::map 10.9 ms
    // std::unordered_map 10.2 ms
    // absl::btree_map 9.0 ms
    // absl::flat_hash_map 8.0 ms
    std::unordered_map<Argb, int>::iterator it = pixel_to_count.find(pixel);
    if (it != pixel_to_count.end()) {
      it->second++;

    } else {
      pixels.push_back(pixel);
      points.push_back(LabFromInt(pixel));
      pixel_to_count[pixel] = 1;
    }
  }

  int cluster_count = std::min((int)max_colors, (int)points.size());

  if (!starting_clusters.empty()) {
    cluster_count = std::min(cluster_count, (int)starting_clusters.size());
  }

  int pixel_count_sums[256] = {};
  std::vector<Lab> clusters;
  clusters.reserve(starting_clusters.size());
  for (int argb : starting_clusters) {
    clusters.push_back(LabFromInt(argb));
  }

  srand(42688);
  int additional_clusters_needed = cluster_count - clusters.size();
  if (starting_clusters.empty() && additional_clusters_needed > 0) {
    for (int i = 0; i < additional_clusters_needed; i++) {
      // Adds a random Lab color to clusters.
      double l = rand() / (static_cast<double>(RAND_MAX)) * (100.0) + 0.0;
      double a =
          rand() / (static_cast<double>(RAND_MAX)) * (100.0 - -100.0) - 100.0;
      double b =
          rand() / (static_cast<double>(RAND_MAX)) * (100.0 - -100.0) - 100.0;
      clusters.push_back({l, a, b});
    }
  }

  std::vector<int> cluster_indices;
  cluster_indices.reserve(points.size());

  srand(42688);
  for (size_t i = 0; i < points.size(); i++) {
    cluster_indices.push_back(rand() % cluster_count);
  }

  std::vector<std::vector<int>> index_matrix(
      cluster_count, std::vector<int>(cluster_count, 0));

  std::vector<std::vector<DistanceToIndex>> distance_to_index_matrix(
      cluster_count, std::vector<DistanceToIndex>(cluster_count));

  for (int iteration = 0; iteration < kMaxIterations; iteration++) {
    // Calculate cluster distances
    for (int i = 0; i < cluster_count; i++) {
      distance_to_index_matrix[i][i].distance = 0;
      distance_to_index_matrix[i][i].index = i;
      for (int j = i + 1; j < cluster_count; j++) {
        double distance = clusters[i].DeltaE(clusters[j]);

        distance_to_index_matrix[j][i].distance = distance;
        distance_to_index_matrix[j][i].index = i;
        distance_to_index_matrix[i][j].distance = distance;
        distance_to_index_matrix[i][j].index = j;
      }

      std::vector<DistanceToIndex> row = distance_to_index_matrix[i];
      std::sort(row.begin(), row.end());

      for (int j = 0; j < cluster_count; j++) {
        index_matrix[i][j] = row[j].index;
      }
    }

    // Reassign points
    bool color_moved = false;
    for (size_t i = 0; i < points.size(); i++) {
      Lab point = points[i];

      int previous_cluster_index = cluster_indices[i];
      Lab previous_cluster = clusters[previous_cluster_index];
      double previous_distance = point.DeltaE(previous_cluster);
      double minimum_distance = previous_distance;
      int new_cluster_index = -1;

      for (int j = 0; j < cluster_count; j++) {
        if (distance_to_index_matrix[previous_cluster_index][j].distance >=
            4 * previous_distance) {
          continue;
        }
        double distance = point.DeltaE(clusters[j]);
        if (distance < minimum_distance) {
          minimum_distance = distance;
          new_cluster_index = j;
        }
      }
      if (new_cluster_index != -1) {
        double distanceChange =
            abs(sqrt(minimum_distance) - sqrt(previous_distance));
        if (distanceChange > kMinDeltaE) {
          color_moved = true;
          cluster_indices[i] = new_cluster_index;
        }
      }
    }

    if (!color_moved && (iteration != 0)) {
      break;
    }

    // Recalculate cluster centers
    double component_a_sums[256] = {};
    double component_b_sums[256] = {};
    double component_c_sums[256] = {};
    for (int i = 0; i < cluster_count; i++) {
      pixel_count_sums[i] = 0;
    }

    for (size_t i = 0; i < points.size(); i++) {
      int clusterIndex = cluster_indices[i];
      Lab point = points[i];
      int count = pixel_to_count[pixels[i]];

      pixel_count_sums[clusterIndex] += count;
      component_a_sums[clusterIndex] += (point.l * count);
      component_b_sums[clusterIndex] += (point.a * count);
      component_c_sums[clusterIndex] += (point.b * count);
    }

    for (int i = 0; i < cluster_count; i++) {
      int count = pixel_count_sums[i];
      if (count == 0) {
        clusters[i] = {0, 0, 0};
        continue;
      }
      double a = component_a_sums[i] / count;
      double b = component_b_sums[i] / count;
      double c = component_c_sums[i] / count;
      clusters[i] = {a, b, c};
    }
  }

  std::vector<Swatch> swatches;
  std::vector<Argb> cluster_argbs;
  std::vector<Argb> all_cluster_argbs;
  for (int i = 0; i < cluster_count; i++) {
    Argb possible_new_cluster = IntFromLab(clusters[i]);
    all_cluster_argbs.push_back(possible_new_cluster);

    int count = pixel_count_sums[i];
    if (count == 0) {
      continue;
    }
    int use_new_cluster = 1;
    for (size_t j = 0; j < swatches.size(); j++) {
      if (swatches[j].argb == possible_new_cluster) {
        swatches[j].population += count;
        use_new_cluster = 0;
        break;
      }
    }

    if (use_new_cluster == 0) {
      continue;
    }
    cluster_argbs.push_back(possible_new_cluster);
    swatches.push_back({possible_new_cluster, count});
  }
  std::sort(swatches.begin(), swatches.end());

  // Constructs the quantizer result to return.

  std::map<Argb, uint32_t> color_to_count;
  for (size_t i = 0; i < swatches.size(); i++) {
    color_to_count[swatches[i].argb] = swatches[i].population;
  }

  std::map<Argb, Argb> input_pixel_to_cluster_pixel;
  for (size_t i = 0; i < points.size(); i++) {
    int pixel = pixels[i];
    int cluster_index = cluster_indices[i];
    int cluster_argb = all_cluster_argbs[cluster_index];
    input_pixel_to_cluster_pixel[pixel] = cluster_argb;
  }

  return {color_to_count, input_pixel_to_cluster_pixel};
}

}  // namespace material_color_utilities
