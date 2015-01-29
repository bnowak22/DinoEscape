//
//  Player.m
//

#import "Player.h"
#import "SKTUtils.h"

@implementation Player

- (instancetype)initWithImageNamed:(NSString *)name {
    if (self == [super initWithImageNamed:name]) {
        self.velocity = CGPointMake(0.0, 0.0);
        self.isStand = YES;
        self.imgSwitchCount = 0;
    }
    return self;
}

- (void)update:(NSTimeInterval)delta
{
    //switch image if needed
    self.imgSwitchCount++;
    if (self.imgSwitchCount > 10) { //change this number to determine when to switch images
        if (!self.isStand && self.onGround) {
            self.texture = [SKTexture textureWithImageNamed:@"small_stand"];
            self.isStand = YES;
        }
        else {
            self.texture = [SKTexture textureWithImageNamed:@"small_walk"];
            self.isStand = NO;
        }
        self.imgSwitchCount = 0;
    }
    
    CGPoint gravity = CGPointMake(0.0, -450.0);
    CGPoint gravityStep = CGPointMultiplyScalar(gravity, delta);
    self.velocity = CGPointAdd(self.velocity, gravityStep);
    
    //jumping
    CGPoint jumpForce = CGPointMake(0.0, 310.0);
    float jumpCutoff = 150.0;
    
    if (self.mightAsWellJump && self.onGround) {
        self.velocity = CGPointAdd(self.velocity, jumpForce);
    } else if (!self.mightAsWellJump && self.velocity.y > jumpCutoff) {
        self.velocity = CGPointMake(self.velocity.x, jumpCutoff);
    } else if (self.collidedTop) {
        self.velocity = CGPointMake(self.velocity.x, 0);
        self.collidedTop = NO;
    }
    
    //foward movement
    CGPoint forwardMove = CGPointMake(150.0, 0.0);
    if (self.forwardMarch) {
        self.velocity = CGPointAdd(self.velocity, forwardMove);
    }
    
    //put limits on movement speeds
    CGPoint minMovement = CGPointMake(0.0, -450);
    CGPoint maxMovement = CGPointMake(150.0, 250.0);
    self.velocity = CGPointMake(Clamp(self.velocity.x, minMovement.x, maxMovement.x), Clamp(self.velocity.y, minMovement.y, maxMovement.y));
    
    CGPoint velocityStep = CGPointMultiplyScalar(self.velocity, delta);
    
    self.desiredPosition = CGPointAdd(self.position, velocityStep);
}

- (CGRect)collisionBoundingBox {
    CGRect boundingBox = CGRectInset(self.frame, 2, 0); //modify hit box inset here (x,y)
    CGPoint diff = CGPointSubtract(self.desiredPosition, self.position);
    return CGRectOffset(boundingBox, diff.x, diff.y);
}

@end
