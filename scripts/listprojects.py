#!/usr/bin/env python

"""Script to list projects ordered by last use date.

Usage: listprojects.py [project_directory]

Requires Python 3.11 or above.

This script will look in every subdir of `project_directory` for git
repositories and return them, sorted by the mtime of the `.git/index` file.
"""

import os
import sys
from dataclasses import dataclass


@dataclass
class Project:
    path: str
    mtime: float


dir = sys.argv[1]
projects: list[Project] = []
files = os.listdir(dir)

for file in files:
    try:
        path = os.path.join(dir, file)
        index = os.path.join(path, ".git", "index")
        mtime = os.path.getmtime(index)
        projects.append(Project(path, mtime))
    except (FileNotFoundError, NotADirectoryError):
        pass

projects.sort(key=lambda p: p.mtime, reverse=True)

for project in projects:
    print(project.path)
