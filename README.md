Async library inspired by CommonJS Promises/A spec
[![Build Status](https://travis-ci.org/kseebaldt/deferred.svg?branch=master)](https://travis-ci.org/kseebaldt/deferred)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

http://wiki.commonjs.org/wiki/Promises/A

## Installation
Via [CocoaPods](http://cocoapods.org):
```ruby
pod 'KSDeferred'
```

# Examples

## Creating a promise
``` objc
	[KSPromise promise:^(resolveType resolve, rejectType reject) {
        [obj doAsyncThing:^(id value, NSError *error) {
			if (error) {
				reject(error);
			} else {
				resolve(value);
			}
		}];
    }];
```

## Creating a resolved promise
``` objc
    KSPromise<NSString *> *promise = [KSPromise resolve:@"A"];
```

## Creating a rejected promise
``` objc
    KSPromise<NSString *> *promise = [KSPromise reject:[NSError errorWithDomain:@"error" code:1 userInfo:nil]];
```

## Adding callback to the promise

``` objc
    [promise then:^id(id value) {
        .. do something ..
        return value;
      } error:^id(NSError *e) {
        .. handle error ..
        return e;
    }];
```

### Shortcut methods when only one callback is needed

``` objc
    [promise then:^id(id value) {
        .. do something ..
        return value;
    }];

    [promise error:^id(NSError error) {
        .. do something ..
        return error;
    }];
```

## Chaining promises

``` objc
    KSPromise *step1 = [KSPromise promise:^(resolveType resolve, rejectType reject) {
        [obj doAsyncThing:^(id value, NSError *error) {
			if (error) {
				reject(error);
			} else {
				resolve(value);
			}
		}];
    }];

    KSPromise *step2 = [step1 then:^id(id value) {
        # value is value returned from first promise
		return [obj doSomethingWith:value];
    } error:^id(NSError *e) {
        # error is error returned from first promise
		return e;
    }];
```

## Always execute a callback, regardless of fulfillment or rejection

``` objc
    [promise finally:^ {
        .. do something ..
    }];
```

## Returning a promise from a callback to chain async work

``` objc
    KSPromise *chained = [promise then:^id(id value) {
		KSPromise promise = [obj doAsyncThing];
		return promise;
    } error:^id(NSError *e) {
        return e;
    }];

    [chained then:^id(id value) {
        # value is value from doAsyncThing
    } error:^id(NSError *e) {
        # error is error from doAsyncThing
    }];
```

## Returning a promise that completes after an array of other promises have completed

``` objc
    KSPromise *waitForMe1 = ...;
    KSPromise *waitForMe2 = ...;
    
    KSPromise *joinedPromise = [KSPromise when: @[
        waitForMe1, waitForMe2
    ]];
```

The method `all:` is a synonym for `when:`.

## Working with generics for improved type safety (Xcode 7 and higher)
``` objc
    KSPromise<NSDate *> *promise = [KSPromise promise:^(resolveType resolve, rejectType reject) {
        [obj doAsyncThing:^(id value, NSError *error) {
			resolve([NSDate date]);
		}];
    }];

    [promise then:^id(NSDate *date) {
        .. do something ..
        return date;
    } error:^id(NSError *e) {
        .. handle error ..
        return e;
    }];
```

## Author

* [Kurtis Seebaldt](mailto:kurtis@pivotallabs.com), Pivotal Labs

Copyright (c) 2013-2016 Kurtis Seebaldt. This software is licensed under the MIT License.
