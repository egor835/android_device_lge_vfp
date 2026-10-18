/*
 * Copyright (C) 2026 The LineageOS Project
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

/*
 * The stock D486 (KK) camera HAL references a static data member that LG
 * added to android::CameraParameters in its libcamera_client:
 *     static int android::CameraParameters::isPreview;
 * Provide it so camera.vendor.msm8226.so can be loaded.
 */
int _ZN7android16CameraParameters9isPreviewE = 0;
