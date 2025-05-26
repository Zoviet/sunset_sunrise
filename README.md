# Calculating sunrise/sunset times for a given location

Based on algorithm by United Stated Naval Observatory, Washington

https://edwilliams.org/sunrise_sunset_algorithm.htm

## Usage

```
local sun = require('sun')

sunrise, sunset,length = sun.get('2025-05-25 21:00:14+03',54.314192, 48.403132)

```


