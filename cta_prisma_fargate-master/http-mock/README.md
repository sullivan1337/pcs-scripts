# Mountebank HTTP Server

For more info on how to setup imposters, see [Mountebank](http://www.mbtest.org/docs/gettingStarted) and the [API contract](http://www.mbtest.org/docs/api/contracts)

```shell
# cd http-mock

# docker run \
    -v $(pwd):/imposters \
    --rm -p 2525:2525 -p 4545:4545 bbyars/mountebank:2.5.0 \
    mb start --configfile /imposters/imposters.ejs --allowInjection --loglevel debug
```