from setuptools import find_packages, setup

setup(
    name='Angel',
    version='0.1.0',
    author='David Rueda',
    author_email='angeldavidstudios@outlook.com',
    description='Real Time Accident detection system using YOLOv11',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    url='https://github.com/AngelDavidStudios',
    packages=find_packages(),
    install_requires=[
        'numpy',
        'opencv-python',
        'torch',
        'ultralytics',
        'fastapi',
        'uvicorn',
        'pydantic'
    ],
    classifiers=[
        'Programming Language :: Python :: 3',
        'Operating System :: OS Independent',
    ],
    python_requires='>=3.6',
)