# Changelog

All notable changes to this project will be documented in this file.

### 0.3.0

- Optimize fingerprint calculation for large images (~24x faster for images >500x500)
- Cache DCT matrix for faster batch processing
- Lower required Ruby version from 3.0 to 2.6
- Improve CLI: support multiple files, `--compare`, `--help`, `--version`

### 0.2.0

Allow passing Vips::Image directly to fingerprint function

### 0.1.0

Initial version