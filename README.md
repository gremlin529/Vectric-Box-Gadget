## Vectric Box Creator Gadget 

This is a fork of the Vectric created box gadget which has had significant enhancements provided by various users through collaborative efforts in the Vectric forums. Most notably user SharkCutUp has contributed greatly. It is now being moved to a git hub location to further foster combined efforts and gadget improvement.

### How can I help?

First get setup to use the git repository (repo) for development purposes, the easiest way to do this is to clone the repo into your vectric gadgets directory and from there you can work with the code directly. It is recommended that you create a branch for your work which can then be submitted back to the repository as a PR for approval and release.

To do this follow these steps

1. Install GIT on your machine, Git is available from [Git - Install for Windows](https://git-scm.com/install/windows)

2. Now that you have git installed open a PowerShell command prompt, I really like to use the Windows Terminal app available here for running my PowerShell windows [Windows Terminal installation | Microsoft Learn](https://learn.microsoft.com/en-us/windows/terminal/install)

3. I also recommending installing the code editor VSCode it makes working with Git a lot easier [Download Visual Studio Code - Mac, Linux, Windows](https://code.visualstudio.com/download)

4. use the following command if you're running VCarve Pro v12.5, change that last bit if you're using different vectric software

   `cd C:\users\public\Documents\Vectric Files\Gadgets\VCarve Pro V12.5`

5. now put the repo in this code location with the following command

   `git clone https://github.com/gremlin529/Vectric-Box-Gadget.git`

6. this puts a copy of the current code in your Vectric gadgets directory and you can now actually start up vectric and you'll see a new gadget called “Vectric-Box-Gadget” and under that you can run it

7. type `cd vectric-box-gadget`

8. `code .`

9. Now you should have a code editor opened and can edit and view the lua file for the script and the html and stylesheets for the html

10. to create a new branch to make changes in type something like `git switch -c <user>/<branchname>` where the name is something descriptive about what you are doing for instance I might have used `git switch -c gremlin/bottomtabs`

It would be a good idea to watch or look up some basic tutorials on working with GIT if you don't have the experience, but using VS Code you can push code up to your branch and then from the github ux create a pull request to reintegrate that code back into the project

## How Releases work

I have created a powershell script called MakeRelease.ps1 which when run will take a version number it will generate the proper files to release a version of the gadget and places it in the releases directory where it can also be pushed for review. In doing this it will do all the work of renaming the files from _dev version to the running version for you.
