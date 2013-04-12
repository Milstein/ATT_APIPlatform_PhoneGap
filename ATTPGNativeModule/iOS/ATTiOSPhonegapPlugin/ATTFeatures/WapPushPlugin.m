//
//  WapPushPlugin.m
//  ATTiOSPhonegapPlugin
//
//  Created by Global Logic on 10/23/12.
//  Copyright (c) 2012 Global Logic. All rights reserved.
//


#import "NSData+Base64.h"
#import "WapPushPlugin.h"

@interface WapPushPlugin(PRIVATEMETHOd)
- (void) sendErrorMessage:(const NSString*)message;
@end

@implementation WapPushPlugin

- (id) initWithDelegate:(id)delegate
{
    self = [super init];
    _delegate = delegate;
    return self;
}

- (void) dealloc
{
    _delegate = nil;
    [super dealloc];
}

- (void)sendWAPPushWithArgument:(NSMutableDictionary*)options
{
    //.................Intiliaze Local variables......................./
    const NSDictionary* mmsRequestparameter = options;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSMutableData *body = [NSMutableData data];
    NSString *contentTypeHeader = nil;
    NSString *paramValue= nil;
    NSString* mmsParameters = nil;
    NSString*        contentType = nil;
    NSUInteger       contentValue;
    ///.....................................///
    
    //.................Procedure......................./
    //Set Header of request
    [request setHTTPMethod:REQUESTMETHOD];
    _setRequiredParamAndCheckFailure(mmsRequestparameter,KEYURL,paramValue,errorMessage);
    [request setURL:[NSURL URLWithString:paramValue]];
    _setRequiredParamAndCheckFailure(mmsRequestparameter,KEYTOKEN,paramValue,errorMessage);
    [request setValue:paramValue forHTTPHeaderField:@"Authorization"];
    _setOptionalParam(mmsRequestparameter,KEYACCEPTTYPE,paramValue);
    [request setValue:paramValue forHTTPHeaderField:@"Accept"];
    //acceptType = ([paramValue isEqualToString:CONTENTTYPEXML] == TRUE) ? CONTENTXML : CONTENTJSON;
    
    //Set body of request set recipent addres
    _setOptionalParam(mmsRequestparameter,KEYCONTENTTYPE,contentType);
    (([contentType isEqualToString:CONTENTTYPEXML] == TRUE) ? (contentValue = CONTENTXML) : ([contentType isEqualToString:CONTENTTYPEURLENCODED] == TRUE) ?
     (contentValue = CONTENTURLENCODED) : (contentValue = CONTENTJSON));
    contentTypeHeader = [NSString stringWithFormat:@"multipart/form-data; type=\"%@\"; start=\"<startpart>\"; boundary=\"%@\"",contentType,requestBoundry];
    [request setValue:contentTypeHeader forHTTPHeaderField:@"Content-Type"];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",requestBoundry] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition:form-data; name=\"root-fields\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@;\r\n",contentType] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-ID:<startpart>\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
#ifdef BODYHASTOBECREATED
    NSDictionary* messageBody= [mmsRequestparameter objectForKey:KEYMESSAGEBODY];
    if(messageBody != nil)
    {
        switch (contentValue)
        {
            case CONTENTJSON:
            {
                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:messageBody options:NSJSONWritingPrettyPrinted error:&error];
                
                if (! jsonData) {
                    _sendErrorMessageToDelegate(_delegate,[error localizedDescription],ATT_WAPPUSH_REQUEST);
                    return;
                } else {
                    mmsParameters = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                }
                break;
            }
            case CONTENTXML:
            case CONTENTURLENCODED:
            {
                mmsParameters = (NSString*)messageBody;
                break;
            }
        }
        [body appendData:[[NSString stringWithFormat:@"%@\r\n",mmsParameters] dataUsingEncoding:NSUTF8StringEncoding]];
    }
#else
    _setRequiredParamAndCheckFailure(mmsRequestparameter,KEYMESSAGEBODY,mmsParameters,errorMessage);
    [body appendData:[[NSString stringWithFormat:@"%@\r\n",mmsParameters] dataUsingEncoding:NSUTF8StringEncoding]];
#endif
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",requestBoundry] dataUsingEncoding:NSUTF8StringEncoding]];
    //.... set attachment for the message
    [body appendData:[[NSString stringWithFormat:@"Content-Type: text/xml\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-ID: <part2@sencha.com>\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"PushContent\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: text/vnd.wap.si\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Length: 12\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"X-Wap-Application-Id: x-wap-application:wml.ua\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString* postData = [mmsRequestparameter objectForKey:KEYWAPPUSHDATA];
    if(postData == nil)
        postData = @"null";
    [body appendData:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",requestBoundry] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];

    //Send request and handle response
    ATTPluginHTTPRequest* httpRequest = [[ATTPluginHTTPRequest alloc] initRequest:request withDelegate:self];
    [httpRequest autorelease];
    _ReleaseObj(request);
}

- (void) sendErrorMessage:(const NSString*)message
{
    NSString *errorString = nil;
    if(message != nil)
        errorString = [NSString stringWithFormat:@"%@",message];
    else
        errorString = [NSString stringWithFormat:@"%@",@"Error while executing request"];
    _sendErrorMessageToDelegate(_delegate,errorString,ATT_WAPPUSH_REQUEST);
}
#pragma mark -
#pragma mark HTTP Delegate
- (void) httpRequest:(ATTPluginHTTPRequest*)request didCompleteRequestWithData:(NSData*)data
{
    if([_delegate respondsToSelector:@selector(pluginFeature:didCompleteRequestWithData:forRequest:)])
        [_delegate pluginFeature:self didCompleteRequestWithData:data forRequest:ATT_WAPPUSH_REQUEST];
}

- (void) httpRequest:(ATTPluginHTTPRequest*)request didFailWithError:(NSError*)error
{
    _sendErrorMessageToDelegate(_delegate,errorMessage,ATT_WAPPUSH_REQUEST);
}


@end
