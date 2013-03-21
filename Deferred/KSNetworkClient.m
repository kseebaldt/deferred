#import "KSNetworkClient.h"
#import "KSDeferred.h"

@interface KSNetworkResponse ()
@property (strong, nonatomic, readwrite) NSURLResponse *response;
@property (strong, nonatomic, readwrite) NSData *data;
@end

@implementation KSNetworkResponse
+ (KSNetworkResponse *)networkResponseWithURLResponse:(NSURLResponse *)response data:(NSData *)data {
    KSNetworkResponse *networkResponse = [[KSNetworkResponse alloc] init];
    networkResponse.response = response;
    networkResponse.data = data;
    return networkResponse;
}
@end

@implementation KSNetworkClient

- (KSPromise *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue {
    KSDeferred *deferred = [KSDeferred defer];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [deferred rejectWithError:error];
        } else {
            [deferred resolveWithValue:[KSNetworkResponse networkResponseWithURLResponse:response
                                                                                    data:data]];
        }
    }];
    return deferred.promise;
}

@end
