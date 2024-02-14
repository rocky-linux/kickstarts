# These should change based on the major/minor release

# Base repos
repo --name=BaseOS --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/6202c09e-6252-4d3a-bcd3-9c7751682970/repo/hashed-BaseOS/$basearch
repo --name=AppStream --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/6202c09e-6252-4d3a-bcd3-9c7751682970/repo/hashed-AppStream/$basearch
repo --name=CRB --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/6202c09e-6252-4d3a-bcd3-9c7751682970/repo/hashed-CRB/$basearch
repo --name=extras --cost=200 --baseurl=https://yumrepofs.build.resf.org/v1/projects/6202c09e-6252-4d3a-bcd3-9c7751682970/repo/hashed-extras/$basearch
repo --name=epel --cost=200 --baseurl=https://dl.fedoraproject.org/pub/epel/10/Everything/$basearch/

# URL to the base os repo
url --url=https://yumrepofs.build.resf.org/v1/projects/6202c09e-6252-4d3a-bcd3-9c7751682970/repo/hashed-BaseOS/$basearch
