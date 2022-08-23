# These should change based on the major/minor release

# Base repos
repo --name=BaseOS --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-BaseOS/$basearch
repo --name=AppStream --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-AppStream/$basearch
repo --name=CRB --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-CRB/$basearch
repo --name=extras --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-extras/$basearch
repo --name=epel --cost=200 --baseurl=https://dl.fedoraproject.org/pub/epel/9/Everything/$basearch/
#repo --name=epel-modular --cost=200 --baseurl=https://dl.fedoraproject.org/pub/epel/9/Modular/$basearch/

# URL to the base os repo
url --url=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-BaseOS/$basearch
