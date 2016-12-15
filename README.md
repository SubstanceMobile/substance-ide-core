# Substance IDE Core

This package manages all of the code-related features of the Substance IDE. This includes code completion, code documentation handling, project handling, code refactoring, code usage, code error detection, code scope detection, and code formatting.

## Project handling

For reading the `.ide` folder for each project. This folder contains an index of the project, metadata about the project, and how this project should be handled.

## Code completion

Automatic completion of code with references to classes, functions, and properties in the project.

## Code documentation

Support for code documentation, and automatic KDoc generation

## Code refactoring

Support for moving, renaming, or in any other way changing a code object

## Code usage model

A model that contains information about where any function, variable, or class is created, referenced, overwritten, or extended.

## Code error detection

Support for detecting errors in syntax or reference in code.

## Code scope detection

Support for detecting the scope of code, that is what parts of the rest of the codebase you can access from the class being edited.

## Code formatting

Support for changing code to follow standards and common practices, especially for layout purposes
