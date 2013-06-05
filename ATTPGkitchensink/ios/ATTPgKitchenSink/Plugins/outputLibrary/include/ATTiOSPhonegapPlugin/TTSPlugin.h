//
//  SpeechPlugin.h
//  ATTiOSPhonegapPlugin
//
//  Created by Saurav Nagpal on 10/23/12.
//  Copyright (c) 2012 Saurav Nagpal. All rights reserved.
//

#import "ATTPluginHTTPRequest.h"
@protocol ATTPluginFeatureHandling;


@interface TTSPlugin : NSObject<ATTPluginHTTPHandling>
{
@private
    id<ATTPluginFeatureHandling>                  _delegate;
}

- (id) initWithDelegate:(id<ATTPluginFeatureHandling>)delegate;
-(void) textToSpeechWithArgument:(NSMutableDictionary*)options;
@end
