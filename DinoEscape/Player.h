//
//  Player.h
//


#import <SpriteKit/SpriteKit.h>

@interface Player : SKSpriteNode
@property (nonatomic, assign) CGPoint velocity;
@property (nonatomic, assign) CGPoint desiredPosition;
@property (nonatomic, assign) BOOL onGround;
@property (nonatomic, assign) BOOL forwardMarch;
@property (nonatomic, assign) BOOL mightAsWellJump;
@property (nonatomic, assign) BOOL collidedTop;
@property (nonatomic, assign) BOOL isStand;
@property int imgSwitchCount;
-(CGRect)collisionBoundingBox;
- (void)update:(NSTimeInterval)delta;
@end
