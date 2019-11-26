"""
@version: Python 3.7
@author: deepglint
@time: 2019/10/31 20:20
@disclaimer：anyone can use this, but take responsibility yourself
@BUG：if deletePageNum>actualPageNum, this code will delete about all pipelines
"""

import requests


# Note: This must need the reposity's creator's access-token(maintainer's is forbidden also)
PRIVATE_TOKEN = 'v-xxxxxxxxxxxxxx'


def get_header():
    headers = {}
    headers['PRIVATE-TOKEN'] = PRIVATE_TOKEN
    headers['Content-Type'] = "application/json"
    return headers


'''
https://docs.gitlab.com/ee/api/pipelines.html#list-project-pipelines
'''


def pipeline_clean(project_id, deletePageNum):
    '''
    :param project_id: gitlab project id
    :param deletePageNum: 想要删除pipeline页数，每页20个pipeline，所以总共删除 20*deletePageNum 条记录（但是会保留第一页）
    :param deletePageNum: pipeline pages that you want to delete; twenty pipelines per page, so totally you will delete 20*deletePageNum pipeline records
    '''
    gitlab_api_url = "https://gitlab.unionfab.com/api/v4/projects/"
    pipeline_list_Url = gitlab_api_url + str(project_id) + "/pipelines"
    pipeline_delete_Url = gitlab_api_url + str(project_id) + "/pipelines"

    if (deletePageNum) <= 1:
        return

    # loop to delete in last page
    for i in range(deletePageNum):
        params = {
            "sort": "asc"
        }
        response = requests.get(url=pipeline_list_Url,
                                headers=get_header(), params=params)
        if len(response.json()) < 20:
            return
        if str(response.status_code).startswith("20"):
            for pipeline in response.json():
                pipeline_id = pipeline["id"]
                delete_url = pipeline_delete_Url+"/"+str(pipeline_id)
                delete_response = requests.delete(
                    url=delete_url, headers=get_header())
                if str(delete_response.status_code).startswith("20"):
                    print("page number "+str(i+1) +
                          ", delete success: ", delete_url)
                else:
                    print("page number "+str(i+1) +
                          ", delete failed: ", delete_url)


if __name__ == "__main__":
    pipeline_clean(project_id=243, deletePageNum=5)
