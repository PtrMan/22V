import time

import gym
from PIL import Image

env = gym.make('MountainCar-v0')
observation, info = env.reset(seed=42, return_info=True)

while True:
    for _ in range(5000):
        action = env.action_space.sample()
        observation, reward, done, info = env.step(action)

        env_screen = env.render(mode = 'rgb_array') # render environment to image

        if True:
            im = Image.fromarray(env_screen)
            im.save("outCurrentFrameFromEnv.png")

        if done:
            observation, info = env.reset(return_info=True)
            break
        
        time.sleep(0.05)

env.close()
