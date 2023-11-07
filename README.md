# Get demographics

## Step 1: get list of published articles

Pull from CrossRef

## Step 2: Get author information, citations, institutional citations

Pull from OpenAlex, but also map to Carnegie classification (will be fuzzy match)


## Supplementary: get filenames, software

Using Krantz data, relate the software, and complexity/size of the repository, to the characteristics collected earlier.

# NOTES

## Running R on Codespaces

```bash
docker run -it --rm -v $(pwd):/project -w /project rocker/verse /bin/bash
```