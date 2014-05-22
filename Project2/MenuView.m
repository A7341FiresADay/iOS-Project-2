//
//  MenuView.m
//  Project2
//
//  Created by Student on 5/6/14.
//  Copyright (c) 2014 WEAREORGANIZED. All rights reserved.
//

#import "MenuView.h"
#import "MyScene.h"
@implementation MenuView
{
    SKLabelNode *_titleLabel;
    SKLabelNode *_playLabel;
    SKLabelNode *_quitLabel;
}
- (id)initWithSize:(CGSize)size
{
    self = [super initWithSize:size];
    if (self) {
        SKSpriteNode *bg =
        [SKSpriteNode spriteNodeWithImageNamed:@"background"];
        bg.position =
        CGPointMake(self.size.width/2, self.size.height/2);
        /*bg.position =
        CGPointMake(self.size.width / 2, self.size.height / 2);
        bg.anchorPoint = CGPointMake(0.5, 0.5); // same as default
        //bg.zRotation = M_PI / 8;*/
        [self addChild:bg];
        [self setBackgroundColor:[UIColor grayColor]];
        
        _titleLabel = [SKLabelNode labelNodeWithFontNamed:@"Menlo-Regular"];
        _playLabel = [SKLabelNode labelNodeWithFontNamed:@"Menlo-Regular"];
        _quitLabel = [SKLabelNode labelNodeWithFontNamed:@"Menlo-Regular"];
        
        _titleLabel.fontSize = 48;
        _playLabel.fontSize = 44;
        _quitLabel.fontSize = 44;
        
        _titleLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)+ 220);
        _playLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)+ 80);
        _quitLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) -230);
        //CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
        
        _titleLabel.text = @"What the Platformer?!?!";
        _playLabel.text = @"Play";
        _quitLabel.text = @"Quit";
        
        [self addChild:_titleLabel];
        [self addChild:_playLabel];
        [self addChild:_quitLabel];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.scene];
    
    if (touchLocation.y > CGRectGetMidY(self.frame)+ 60)
    {
        MyScene * myScene = [[MyScene alloc] initWithSize:self.size];
        
        [self.view presentScene:myScene];
        
    }
    else exit(0);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
