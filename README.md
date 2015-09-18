Async library inspired by CommonJS Promises/A spec
[![Build Status](https://travis-ci.org/kseebaldt/deferred.svg?branch=master)](https://travis-ci.org/kseebaldt/deferred)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

http://wiki.commonjs.org/wiki/Promises/A

## Installation
Via [Cocoapods](http://cocoapods.org):
```ruby
pod 'KSDeferred'
```

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

## Returning a promise from a callback to chain async work

    KSPromise *chained = [promise then:^id(id value) {
        KSDeferred *nextDeferred = [KSDeferred defer];
        return nextDeferred.promise;
    } error:^id(NSError *e) {
        return e;
    }];

    [chained then:^id(id value) {
        # value is value the returned promise resolves with
    } error:^id(NSError *e) {
        # error is error the returned promise rejects with
    }];

## Returning a promise that completes after an array of other promises have completed

    KSDeferred *waitForMe1 = [KSDeferred deferred];
    KSDeferred *waitForMe2 = [KSDeferred deferred];
    
    KSPromise *joinedPromise = [KSPromise when: @[
        [waitForMe1 promise],
        [waitForMe2 promise]
    ]];

## Resolving a promise
    [deferred resolveWithValue:@"VALUE"];

## Rejecting a promise
    NSError *someError;
    [deferred rejectWithError:someError];

## Working with generics for improved type safety (Xcode 7 and higher)
    KSDeferred<NSDate *> *deferred = [KSDeferred defer];
    KSPromise<NSDate *> *promise = deferred.promise;

    [deferred resolveWithValue:[NSDate date]];

    [promise then:^id(NSDate *date) {
        .. do something ..
        return date;
    } error:^id(NSError *e) {
        .. handle error ..
        return e;
    }];


## Author

* [Kurtis Seebaldt](mailto:kurtis@pivotallabs.com), Pivotal Labs

Copyright (c) 2013 Kurtis Seebaldt. This software is licensed under the MIT License.
