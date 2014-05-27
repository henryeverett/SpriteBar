//
//  SpriteBar.h
//  SpriteBar
//
//  Created by Henry Everett on 27/05/2014.
//  Copyright (c) 2014 Henry Everett. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SpriteBar : SKSpriteNode

@property (nonatomic, strong) NSString *textureReference;

/* Initialise with default progress bar graphics. */
- (id)init;
/* Initialise with custom progress bar graphics. */
- (id)initWithTextureAtlas:(SKTextureAtlas *)textureAtlas;
/* Start incrementing progress bar using timer. */
- (void)startBarProgressWithTimer:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector;
/* Invalidate the timer. */
- (void)invalidateTimer;
/* Set progress and calculate as a percentage of total number. */
- (void)setProgressWithValue:(CGFloat)progress ofTotal:(CGFloat)maxValue;
/* Set progress manually. */
- (void)setProgress:(CGFloat)progress;
/* Reset progress bar to zero. */
- (void)resetProgress;


@end
