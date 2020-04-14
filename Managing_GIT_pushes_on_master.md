# Managing Git pushes on master

This document explains how it is possible to approach differently the way a
commit become part of master, avoiding unwanted merges, due to the automatic
ways git uses to fix conflicts.
This can lead to this kind of situation in the master repo:

```
| * 0662160cfe1b - (2020-04-01 18:14:18 +0200)  Commit #11 <User2>
| * e880c2c62c6e - (2020-04-01 17:32:34 +0200)  Commit #10 <User3>
| * aa721f8f350a - (2020-04-01 12:36:32 +0200)  Commit #9 <User1>
* |   77ab6238ae72 - (2020-04-02 10:40:03 +0200)  Merge branch 'master' of ssh://myserver/var/git/puppet <User2>
|\ \  
| * | 6235d4ddad76 - (2020-04-01 18:11:02 +0200)  Commit #8 <User1>
| * | 69e6e5f3a904 - (2020-04-01 18:11:02 +0200)  Commit #7 <User1>
| * | c72dadaa329b - (2020-04-01 18:11:01 +0200)  Commit #6 <User1>
| * | fdd97696aa5d - (2020-04-01 18:11:01 +0200)  Commit #5 <User1>
* | | 2e970166e03b - (2020-04-02 10:36:23 +0200)  Commit #3 <User2>
|/ /  
* | 620258d4da35 - (2020-04-01 10:55:13 +0200)  Commit #4 <User2>
|/  
* a52f3475907d - (2020-03-31 19:18:11 +0200)  Commit #2 <User3>
* de00acdbbe06 - (2020-03-31 17:31:49 +0200)  Commit #1 <User1>
```

What a mess, isn't it?

## When there are no changes in the meantime

In theory, if no additional commits are made in between your changes, the
workflow can be:

0. ```git checkout master``` # ensure you're on master branch
1. ```git pull``` # get the latest commits from master branch
2. Make your changes on the files
3. ```git commit``` # commit changes into the personal local branch
4. ```git pull``` # get the latest commits for master branch
5. ```git push``` # push commits on origin/master

## When something changed in the meantime

If during the step 4 nothing happens, then you're good, othewise you will
be asked to confirm a merge (which cannot be aborted). This means that
something changed in the repo while you were making changes.

If you accept the merge and push it to master you will find yourself in the
situation described above, making hard for other developers to understand the
changes flow.

To have a linear sequence of commits in the master branch, it is possible to
avoid the merge by using this workflow:

0. ```git checkout master``` # ensure you're on master branch
1. ```git pull``` # get the latest commits from master branch
2. Make your changes on the files
3. ```git commit``` # commit changes into the personal local branch
4. ```git pull``` # get the latest commits from master with a merge request
   from git, vim or the default editor opens and you must continue
5. ```git reset --hard HEAD^1``` # remove the merge
6. ```git log``` # get the id of &lt;yourcommithash&gt;
7. ```git reset --hard HEAD^1``` # remove your commit from the master branch on
   the local repo
8. ```git pull``` # get all the new modifications from master (it should not
   ask for any merge)
9. ```git cherry-pick <yourcommithash>``` # pick your specific commit with hash
10. ```git push``` # push commits on origin/master

When you've got a single quick commit to push, then the workflow could be a
little smoother:

0. ```git checkout master``` # ensure you're on master branch
1. ```git pull``` # get the latest commits from master branch
2. Make your changes on the files
3. ```git commit``` # commit changes into the personal local branch
4. ```git log``` # get the id of &lt;yourcommithash&gt;
5. ```git reset --hard HEAD^1``` # remove your last commit
6. ```git pull``` # get the latest commits for master branch
7. ```git cherry-pick <yourcommithash>``` # pick your specific commit with hash
8. ```git push``` # push commits on origin/master

## Creating local branches when you have a huge amount of changes

When there's a huge amount of modifications (with related commits) to be done,
it is useful to create a local branch named after the related topic:

0. ```git checkout master``` # ensure you're on master branch
1. ```git pull``` # get the latest commits for master branch
2. ```git checkout -b <mynewfeature>``` # create a new local branch
3. Make your changes on the files
4. ```git commit``` # commit changes into the personal local branch
5. ```git checkout master```
6. ```git pull``` # this will pull any new commit made in the meantime on
   master
7. ```git checkout <mynewfeature>``` # move back to the personal local branch
8. ```git rebase master``` # put the branch commits on top of the master's one
9. ```git checkout master``` # go back to local master branch
10. ```git merge <mynewfeature>``` # merge all the commits of the local branch
    into master
11. ```git push``` # push commits on origini/master

Rebase it's always the best choice while playing with multiple commits.
