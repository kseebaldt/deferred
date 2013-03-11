Async library inspired by CommonJS Promises/A spec

# Examples

## Creating a deferred object and returning its promise 

    KSDeferred *deferred = [KSDeferred defer];
    return deferred.promise;

## Adding callback to the promise

    [promise then:^id(id value) {
        .. do something ..
        return value;
      } error:^id(NSError *e) {
        .. handle error ..
        return e;
    }];

## Chaining promises

    KSPromise *chained = [promise then:^id(id value) {
        return value;
    } error:^id(NSError *e) {
        return e;
    }];

    [chained then:^id(id value) {
        # value is value returned from first promise
    } error:^id(NSError *e) {
        # error is error returned from first promise
    }];

## Resolving a promise
    [deferred resolveWithValue:@"VALUE"];

## Rejecting a promise
    NSError *someError;
    [deferred rejectWithError:someError];
