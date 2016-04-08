#import "KSNetworkClient.h"

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

