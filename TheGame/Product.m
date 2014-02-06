//
//  Product.m
//  TheGame
//
//  Created by Nanyi Jiang on 2/5/2014.
//  Copyright (c) 2014 Nanyi Jiang. All rights reserved.
//

#import "Product.h"

@implementation Product {
    CGSize _size;
}

double dot(CGPoint p1, CGPoint p2) {
    return p1.x * p2.x + p1.y * p2.y;
}

double cross(CGPoint p1, CGPoint p2, CGPoint base) {
    p1.x -= base.x;
    p2.x -= base.x;
    p1.y -= base.y;
    p2.y -= base.y;
    return p1.x * p2.y - p1.y * p2.x;
}

- (NSValue *)intersectionOfLineFrom:(CGPoint)p1 to:(CGPoint)p2 withLineFrom:(CGPoint)p3 to:(CGPoint)p4
{
    CGFloat d = (p2.x - p1.x)*(p4.y - p3.y) - (p2.y - p1.y)*(p4.x - p3.x);
    if (d == 0)
        return nil; // parallel lines
    CGFloat u = ((p3.x - p1.x)*(p4.y - p3.y) - (p3.y - p1.y)*(p4.x - p3.x))/d;
    CGFloat v = ((p3.x - p1.x)*(p2.y - p1.y) - (p3.y - p1.y)*(p2.x - p1.x))/d;
    if (u < 0.0 || u > 1.0)
        return nil; // intersection point not between p1 and p2
    if (v < 0.0 || v > 1.0)
        return nil; // intersection point not between p3 and p4
    CGPoint intersection;
    intersection.x = p1.x + u * (p2.x - p1.x);
    intersection.y = p1.y + u * (p2.y - p1.y);
    
    return [NSValue valueWithCGPoint:intersection];
}

- (CGMutablePathRef)pathFromPoints:(NSArray *)points {
    CGMutablePathRef path = CGPathCreateMutable();
    if (points && points.count > 0) {
        CGPoint p = [(NSValue *)[points objectAtIndex:0] CGPointValue];
        CGPathMoveToPoint(path, nil, p.x, p.y);
        for (int i = 1; i < points.count; i++) {
            p = [(NSValue *)[points objectAtIndex:i] CGPointValue];
            CGPathAddLineToPoint(path, nil, p.x, p.y);
        }
    }
    CGPathCloseSubpath(path);
    return path;
}


- (void)initPhysicsWithImage:(UIImage *)image {
    [self initPhysicsWithImage:image size:[image size]];
}

- (void)initPhysicsWithImage:(UIImage *)image size:(CGSize)size {
    self.points = [[NSMutableArray alloc] initWithObjects:
                   [NSValue valueWithCGPoint:CGPointMake(-size.width/2, size.height/2)],
                   [NSValue valueWithCGPoint:CGPointMake(size.width/2, size.height/2)],
                   [NSValue valueWithCGPoint:CGPointMake(size.width/2, -size.height/2)],
                   [NSValue valueWithCGPoint:CGPointMake(-size.width/2, -size.height/2)], nil];
    CGPathRef path = [self pathFromPoints:self.points];
    self.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    SKShapeNode *shapeNode = [[SKShapeNode alloc] init];
    shapeNode.path = path;
    
    SKSpriteNode *drawable = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImage:image]];
    drawable.size = size;
    self.drawable = drawable;
    shapeNode.fillColor = [UIColor whiteColor];
    [self addChild:shapeNode];
    self.maskNode = shapeNode;
    [self addChild:self.drawable];
    
    _size = size;
}

- (NSArray *)populatePoints {
    NSMutableArray *newPoints = [[NSMutableArray alloc] init];
    for (NSValue *value in self.points) {
        CGPoint point = [value CGPointValue];
        double c = cos(self.zRotation);
        double s = sin(self.zRotation);
        CGPoint newPoint = CGPointMake(point.x * c - point.y * s + self.position.x,
                                       point.x * s + point.y * c + self.position.y);
        [newPoints addObject:[NSValue valueWithCGPoint:newPoint]];
    }
    return newPoints;
}

- (NSArray *)sliceAtPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint {
    NSMutableArray *part1 = [[NSMutableArray alloc] init];
    NSMutableArray *part2 = [[NSMutableArray alloc] init];
    NSArray *newPoints = [self populatePoints];
    int intersected = 0;
    int intersectIndex1, intersectIndex2;
    CGPoint intersectPoint1, intersectPoint2;
    for (int i = 0; i < [newPoints count]; i++) {
        int j = (i+1) % [newPoints count];
        CGPoint p1 = [[newPoints objectAtIndex:i] CGPointValue];
        CGPoint p2 = [[newPoints objectAtIndex:j] CGPointValue];
        NSValue *intersection = [self intersectionOfLineFrom:startPoint to:endPoint withLineFrom:p1 to:p2];
        if (intersection) {
            intersected++;
            if (intersected == 1) {
                intersectIndex1 = j;
                intersectPoint1 = [intersection CGPointValue];
            }
            if (intersected == 2) {
                intersectIndex2 = j;
                intersectPoint2 = [intersection CGPointValue];
                break;
            }
        }
    }
    if (intersected < 2) {
        return nil;
    }
    [part1 addObject:[NSValue valueWithCGPoint:intersectPoint1]];
    int index = intersectIndex1;
    while (index != intersectIndex2) {
        [part1 addObject:[newPoints objectAtIndex:index]];
        index = (index + 1) % [newPoints count];
    }
    [part1 addObject:[NSValue valueWithCGPoint:intersectPoint2]];
    [part2 addObject:[NSValue valueWithCGPoint:intersectPoint2]];
    index = intersectIndex2;
    while (index != intersectIndex1) {
        [part2 addObject:[newPoints objectAtIndex:index]];
        index = (index + 1) % [newPoints count];
    }
    [part2 addObject:[NSValue valueWithCGPoint:intersectPoint1]];
    return [NSArray arrayWithObjects:part1,
            part2, nil];
}

- (void)initPhysicsWithPoints:(NSArray *)points {
    CGPathRef path = [self pathFromPoints:points];
    self.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    SKShapeNode *shapeNode = [[SKShapeNode alloc] init];
    shapeNode.path = path;
    shapeNode.fillColor = [UIColor whiteColor];
    self.points = [points mutableCopy];
    [self addChild:shapeNode];
}

- (void)nudge:(CGVector)direction {
    [self.physicsBody applyImpulse:CGVectorMake((random()/RAND_MAX - 0.5) * 500, (random()/RAND_MAX - 0.5) * 500)];
    [self.physicsBody applyAngularImpulse:random()/RAND_MAX * 500];
}

- (void)setDrawableSize:(CGSize)size rotation:(CGFloat)rotation offset:(CGPoint)offset {
    _size = size;
    self.drawable.size = size;
    self.drawable.zRotation = rotation;
    self.drawable.position = offset;
}

- (CGSize)size {
    return _size;
}

@end
