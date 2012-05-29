#import "NSURLConnection+Deferred.h"
#import "KSPromise.h"

@implementation NSURLConnection (Deferred)

+ (KSPromise *)sendRequest:(NSURLRequest *)request {
    return [self sendRequest:request queue:[NSOperationQueue mainQueue]];
}

+ (KSPromise *)sendRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue {
    KSDeferred *deferred = [[KSDeferred alloc] init];

    [self sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [deferred rejectWithError:error];
        } else {
            [deferred resolveWithValue:[NSArray arrayWithObjects:response, data, nil]];
        }
    }];
    return deferred.promise;
}

@end
