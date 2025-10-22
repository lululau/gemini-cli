/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import { fileURLToPath } from 'node:url';

let fileUrl = import.meta.url;
console.info(fileUrl);

let filePath = fileURLToPath(fileUrl);
console.info(filePath);

console.info(import.meta.filename);

console.info(import.meta.dirname);

console.info(import.meta.main);
