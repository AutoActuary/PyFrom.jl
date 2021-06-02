# PyFrom.jl

This module helps in duplicating some extra python import syntax, more specifically the syntax:
```
from module.submodule import a, b, sea as c
```

### Example
```
Using PyFrom
@pyfrom math import inf as py∞, pi as pyπ, tau
```

