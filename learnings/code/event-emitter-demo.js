/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import { EventEmitter } from 'node:events';

const emitter = new EventEmitter();
emitter.on('test', () => {
  console.info('test event received');
});
emitter.emit('test');