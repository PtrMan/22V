import time
import shutil

import gym
from PIL import Image

#env = gym.make('MountainCar-v0')
env = gym.make('LunarLander-v2')

observation, info = env.reset(seed=42, return_info=True)

while True:
    for _ in range(5000):
        action = env.action_space.sample()
        observation, reward, done, info = env.step(action)

        env_screen = env.render(mode = 'rgb_array') # render environment to image

        if True:
            im = Image.fromarray(env_screen)
            im.save("outCurrentFrameFromEnv_temp.png")

            shutil.move('outCurrentFrameFromEnv_temp.png', 'outCurrentFrameFromEnv.png') # move file to destination to make it look like an atomic update of the image

        if done:
            observation, info = env.reset(return_info=True)
            break
        
        #time.sleep(0.05)
        time.sleep(0.3) # slow motion because vision is to slow

env.close()
