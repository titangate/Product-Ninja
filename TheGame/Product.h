//
//  Product.h
//  TheGame
//
//  Created by Nanyi Jiang on 2/5/2014.
//  Copyright (c) 2014 Nanyi Jiang. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Product : SKCropNode
@property (nonatomic) SKPhysicsBody *body;
@property (nonatomic) NSMutableArray *points;
@property (nonatomic) SKSpriteNode *drawable;
- (NSArray *)populatePoints;
- (NSArray *)sliceAtPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint;
- (void)initPhysicsWithImage:(UIImage *)image size:(CGSize)size;
- (void)initPhysicsWithImage:(UIImage *)image;
- (void)initPhysicsWithPoints:(NSArray *)points;
- (void)setDrawableSize:(CGSize)size rotation:(CGFloat)rotation offset:(CGPoint)offset;
- (CGSize)size;
- (void)nudge:(CGVector)direction;
@end
