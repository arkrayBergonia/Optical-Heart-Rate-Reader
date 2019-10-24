//
//  Fiter.h
//  HeartRate_Demo
//
//  Created by Gurpreet Singh on 31/10/2013.
//  Copyright (c) 2015 Pubnub. All rights reserved.
//

/*
 This filter class is a simple band pass filter that removes any DC component and any high frequency noise
 このフィルタクラスは、任意のDC成分と任意の高周波ノイズを除去する単純なバンドパスフィルタであります
 source: https://www.pubnub.com/blog/tutorial-realtime-ios-heart-rate-monitor-dashboard/
 */

#import <Foundation/Foundation.h>

#define NZEROS 10
#define NPOLES 10

@interface Fiter : NSObject {
    float xv[NZEROS+1], yv[NPOLES+1];
}

-(float) processValue:(float) value;


@end
