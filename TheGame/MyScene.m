//
//  MyScene.m
//  TheGame
//
//  Created by Nanyi Jiang on 2/5/2014.
//  Copyright (c) 2014 Nanyi Jiang. All rights reserved.
//

#import "MyScene.h"
#import "Product.h"

@implementation MyScene {
    CGPoint _startLocation, _endLocation;
    SKShapeNode *_lineNode;
    SKLabelNode *_labelNode;
    NSInteger _credit;
    NSInteger _displayCredit;
    NSInteger turn;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        SKNode *groundNode = [[SKNode alloc] init];
        groundNode.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(0, 0) toPoint:CGPointMake(size.width, 0)];
        [self addChild:groundNode];
        
        SKNode *wallNode1 = [[SKNode alloc] init];
        wallNode1.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(0, 0) toPoint:CGPointMake(0, size.height)];
        [self addChild:wallNode1];
        SKNode *wallNode2 = [[SKNode alloc] init];
        wallNode2.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(size.width, 0) toPoint:CGPointMake(size.width, size.height)];
        [self addChild:wallNode2];
        [self removeAllChildren];
        _lineNode = [[SKShapeNode alloc] init];
        [self addChild:_lineNode];
        
        self.physicsWorld.gravity = CGVectorMake(0, -5);
        
        _labelNode = [[SKLabelNode alloc] initWithFontNamed:@"Chalkduster"];
        _labelNode.position = CGPointMake(50, 25);
        [self addChild:_labelNode];
    }
    NSTimer *timer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(launchProducts) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return self;
}

- (void)launchProducts {
    CGSize size = self.size;
    if (turn % 10 == 0) {
        Product *sprite = [[Product alloc] init];
        SKAction *rotation = [SKAction rotateByAngle: M_PI/4.0 duration:0];
        //and just run the action
        [sprite runAction: rotation];
        
        NSString *imagePath = [NSString stringWithFormat:@"item%d.jpg", rand()%100];
        [sprite initPhysicsWithImage:[UIImage imageNamed:imagePath] size:CGSizeMake(300, 300)];
        
        sprite.position = CGPointMake(CGRectGetMidX(self.view.bounds), -300);
        [self addChild:sprite];
        sprite.physicsBody.velocity = CGVectorMake(0, 1300);
    } else {
        for (int i = 0; i < 5; i++) {
            [self addShipAtLocation:CGPointMake(random() % (int)size.width, random() % (int)size.height - 300)];
        }
    }
}

- (void)updateCredit:(NSInteger)deltaCredit {
    _credit += deltaCredit;
}

#define kDim 128
- (void)addShipAtLocation:(CGPoint)location {
    Product *sprite = [[Product alloc] init];
    SKAction *rotation = [SKAction rotateByAngle: M_PI/4.0 duration:0];
    //and just run the action
    [sprite runAction: rotation];
    
    sprite.position = location;
    NSString *imagePath = [NSString stringWithFormat:@"item%d.jpg", rand()%100];
    [sprite initPhysicsWithImage:[UIImage imageNamed:imagePath]];
    
    [self addChild:sprite];
    sprite.physicsBody.velocity = CGVectorMake(0, 1000);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        _startLocation = [touch locationInNode:self];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sliceFromPoint:_startLocation toPoint:_endLocation];
    _startLocation = CGPointZero;
    _endLocation = CGPointZero;
    _lineNode.path = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        _endLocation = [touch locationInNode:self];
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, _startLocation.x, _startLocation.y);
    CGPathAddLineToPoint(path, NULL, _endLocation.x, _endLocation.y);
    
    _lineNode.path = path;
    [_lineNode setStrokeColor:[SKColor redColor]];
}

- (void)sliceFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint {
    [self.physicsWorld enumerateBodiesAlongRayStart:startPoint end:endPoint usingBlock:^(SKPhysicsBody *body, CGPoint point, CGVector normal, BOOL *stop) {
        if ([self.physicsWorld bodyAtPoint:endPoint] == body || [self.physicsWorld bodyAtPoint:startPoint] == body) {
            //return;
        }
        Product *product = (Product *)body.node;
        
        NSArray *pointGroups = [product sliceAtPoint:startPoint toPoint:endPoint];
        if (pointGroups) {
            CGSize size = product.size;
            CGPoint offset = product.position;
            CGFloat rotation = product.zRotation;
            [product removeFromParent];
            for (NSArray *points in pointGroups) {
                Product *shadow = [[Product alloc] init];
                [shadow initPhysicsWithPoints:points];
                [self addChild:shadow];
                
                [shadow setDrawableSize:size rotation:rotation offset:offset];
                SKAction *fade = [SKAction fadeAlphaTo:0 duration:1];
                [shadow runAction:fade completion:^{
                    [shadow removeFromParent];
                }];
                [shadow nudge:CGVectorMake(endPoint.x - startPoint.x, endPoint.y - startPoint.y)];
                [self updateCredit:5];
            }
        }
    }];
}

-(void)update:(CFTimeInterval)currentTime {
    [_labelNode setText:[NSString stringWithFormat:@"$%d", _credit]];
    for (SKNode *node in self.children) {
        if (node.position.y < -500) {
            [node removeFromParent];
        }
    }
}

@end
