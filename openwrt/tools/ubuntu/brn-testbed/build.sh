#!/bin/sh

(cd brn-testbed-0.0.1; tar -czf ../brn-testbed-0.0.1.tar.gz share/)
(cd brn-testbed-0.0.1; debuild -uc -us)

