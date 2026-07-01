# SkillHub API Notes

- Base URL: `https://skill.local.asstar.net`
- Token source: local vault at runtime
- List skills: `GET /api/v1/skills?page=0&size=50`
- Show skill metadata: `GET /api/v1/skills/{slug}`
- Pull/fetch package zip: `GET /api/v1/skills/{namespace}/{slug}/package`
- Push/publish skill package: `POST /api/v1/skills`
- The package fetch endpoint expects both namespace and slug.
