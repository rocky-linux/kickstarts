# These should change based on the major/minor release

# Base repos
repo --name=BaseOS --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-BaseOS/$basearch
repo --name=AppStream --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-AppStream/$basearch
repo --name=CRB --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-CRB/$basearch
repo --name=extras --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-extras/$basearch

repo --name="elrepo-kernel" --baseurl=https://elrepo.org/linux/kernel/el9/$basearch/ --cost=200

# URL to the base os repo
url --url=https://yumrepofs.build.resf.org/v1/projects/55b17281-bc54-4929-8aca-a8a11d628738/repo/hashed-BaseOS/$basearch
