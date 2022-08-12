Unsupervised Vision System

### What is my purpose?

 * be realtime (ne separation between training and inference phases like in most contemporary ML systems)
 * be open to new knowledge
 * be able to handle real world imagery

### How to run?

see in file EntryVisionManualTest0.hx for up to date information on how to run it.

### dependencies

#### JVM

We recommend running [GraalVM](https://www.graalvm.org/downloads/), because it should be faster than most other JVM's


#### Python-libs + utilities

for pyUtils (initial package) <br />
```pip install numpy``` <br />
```pip install opencv-python``` <br />

for dataprocessing <br />
```pacman -S imagemagick``` for conversion of images <br />

#### Python OpenAI Gym

```pip install -U gym[all]```
```python -c 'import gym; gym.make("FrozenLake-v1")'```
