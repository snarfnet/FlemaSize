import jwt, time, requests, sys

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
# TODO: ASCアプリレコード作成後に実IDを設定する
APP_ID = 'REPLACE_WITH_APP_ID'
BUILD_NUMBER = sys.argv[1]
VERSION = sys.argv[2] if len(sys.argv) > 2 else '1.0'

WHATS_NEW = '最初のバージョンです。硬貨を一緒に置いて撮るだけで、商品のサイズがわかります。'

p8 = open('/tmp/asc_key.p8').read()


def token():
    return jwt.encode({'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200,
                       'aud': 'appstoreconnect-v1'}, p8, algorithm='ES256', headers={'kid': KEY_ID})


def api(method, path, **kwargs):
    return requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}',
                            headers={'Authorization': f'Bearer {token()}', 'Content-Type': 'application/json'}, **kwargs)


print(f'Waiting for build {BUILD_NUMBER}...')
build_id = None
for i in range(80):
    r = api('GET', f'/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1')
    if r.json().get('data'):
        build_id = r.json()['data'][0]['id']
        print(f'Build ready: {build_id}')
        break
    print(f'  waiting... ({i+1}/80)')
    time.sleep(30)

if not build_id:
    print('Build not found after 40 min.')
    sys.exit(0)

api('PATCH', f'/builds/{build_id}',
    json={'data': {'type': 'builds', 'id': build_id, 'attributes': {'usesNonExemptEncryption': False}}})

r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=1')
version_id = None
version_state = None
if r.json().get('data'):
    version_id = r.json()['data'][0]['id']
    version_state = r.json()['data'][0]['attributes']['appStoreState']
    print(f'Latest version: {version_id} state={version_state}')

if version_state in ('WAITING_FOR_REVIEW', 'IN_REVIEW'):
    print('Already in review.')
    sys.exit(0)

if not version_id or version_state in ('READY_FOR_SALE', 'READY_FOR_DISTRIBUTION'):
    print('Creating new version...')
    r = api('POST', '/appStoreVersions', json={'data': {
        'type': 'appStoreVersions',
        'attributes': {'platform': 'IOS', 'versionString': VERSION},
        'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}}})
    if r.status_code not in (200, 201):
        print(f'Create version failed: {r.text[:300]}')
        sys.exit(1)
    version_id = r.json()['data']['id']

# whatsNew（更新版で必須）
for loc in api('GET', f'/appStoreVersions/{version_id}/appStoreVersionLocalizations').json().get('data', []):
    api('PATCH', f'/appStoreVersionLocalizations/{loc["id"]}',
        json={'data': {'type': 'appStoreVersionLocalizations', 'id': loc['id'],
                       'attributes': {'whatsNew': WHATS_NEW}}})

r = api('PATCH', f'/appStoreVersions/{version_id}/relationships/build',
        json={'data': {'type': 'builds', 'id': build_id}})
print(f'Build assigned: {r.status_code}')

for state in ['UNRESOLVED_ISSUES', 'READY_FOR_REVIEW', 'WAITING_FOR_REVIEW']:
    for sub in api('GET', f'/apps/{APP_ID}/reviewSubmissions?filter[state]={state}').json().get('data', []):
        api('PATCH', f'/reviewSubmissions/{sub["id"]}',
            json={'data': {'type': 'reviewSubmissions', 'id': sub['id'], 'attributes': {'canceled': True}}})
        print(f'Canceled {sub["id"]}')

r = api('POST', '/reviewSubmissions', json={'data': {'type': 'reviewSubmissions',
        'attributes': {'platform': 'IOS'}, 'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}}})
if r.status_code != 201:
    print(f'Create submission failed: {r.text[:300]}')
    sys.exit(1)
sub_id = r.json()['data']['id']

for i in range(10):
    r = api('POST', '/reviewSubmissionItems', json={'data': {'type': 'reviewSubmissionItems',
            'relationships': {'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': sub_id}},
                              'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version_id}}}}})
    print(f'Add item {i+1}: {r.status_code}')
    if r.status_code == 201:
        break
    time.sleep(15)

r = api('PATCH', f'/reviewSubmissions/{sub_id}',
        json={'data': {'type': 'reviewSubmissions', 'id': sub_id, 'attributes': {'submitted': True}}})
print(f'Submit: {r.status_code} {r.json()["data"]["attributes"]["state"] if r.status_code == 200 else r.text[:200]}')
