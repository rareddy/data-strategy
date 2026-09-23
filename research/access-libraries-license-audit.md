# Supporting access libraries: license evidence

Checked 2026-09-18. These libraries were discussed during feasibility work; they are not substitutes for an off-the-shelf DCH product. This is source/license evidence, not certification of a resolved dependency graph or container.

| Library or interface | Evidence | Qualification result |
| --- | --- | --- |
| Apache Arrow Java / Flight | [Apache project license](https://github.com/apache/arrow-java/blob/main/LICENSE.txt) | Permissive project source. Selected client/server artifacts and bundled dependency notices still need review. A protocol name does not determine a third-party implementation's license. |
| Apache ADBC, including inspected PostgreSQL driver source | [Project license](https://github.com/apache/arrow-adbc/blob/main/LICENSE.txt), [PostgreSQL implementation](https://github.com/apache/arrow-adbc/blob/main/c/driver/postgresql/postgresql.cc) | Apache-2.0 source evidence. Does not qualify every third-party ADBC driver or distribution. |
| PostgreSQL libpq | [PostgreSQL license](https://www.postgresql.org/about/licence/) | Permissive PostgreSQL license; not literally MIT/Apache. Linked libraries in a chosen binary remain part of its audit. |
| PostgreSQL JDBC | [Driver license](https://jdbc.postgresql.org/license/) | BSD-2-Clause, permissive. Does not certify a surrounding product's adapter. |
| SQLAlchemy | [License](https://github.com/sqlalchemy/sqlalchemy/blob/main/LICENSE) | MIT. The selected dialect and underlying database driver have separate licenses. |
| Psycopg 3 | [License](https://github.com/psycopg/psycopg/blob/master/LICENSE.txt) | LGPL v3; does not meet a permissive-only selection rule. Earlier API examples were feasibility evidence, not a dependency selection. |
| Boto3 and Botocore | [Boto3 license](https://github.com/boto/boto3/blob/develop/LICENSE), [Botocore license](https://github.com/boto/botocore/blob/develop/LICENSE.txt) | Apache-2.0 source evidence. Dependency versions and optional packages remain to be qualified. Supports an object-access mechanism, not a complete registration product. |
| JDBC | Standard interface, not one distributable driver | Assess each vendor driver, adapter and version. Calling a connector JDBC-based supplies no license conclusion. |

Do not infer permissive licensing of an application from a permissive transport, SDK, standard, or driver. Conversely, discovering a nonpermissive optional dependency does not change the license of every file in a project; it disqualifies the selected path under the current requirement unless that path can be changed using supported, qualified packaging.
