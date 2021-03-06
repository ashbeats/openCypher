#
# Copyright 2016 "Neo Technology",
# Network Engine for Objects in Lund AB (http://neotechnology.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Feature: MergeRelationshipAcceptance

  Scenario: Creating a relationship
    Given an empty graph
    And having executed:
      """
      CREATE (:A), (:B)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE]->(b)
      RETURN count(*)
      """
    Then the result should be:
      | count(*) |
      | 1        |
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Matching a relationship
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE]->(b)
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 1        |
    And no side effects

  Scenario: Matching two relationships
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE]->(b)
      CREATE (a)-[:TYPE]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE]->(b)
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 2        |
    And no side effects

  Scenario: Filtering relationships
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE {name: 'r1'}]->(b)
      CREATE (a)-[:TYPE {name: 'r2'}]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE {name: 'r2'}]->(b)
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 1        |
    And no side effects

  Scenario: Creating relationship when all matches filtered out
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE {name: 'r1'}]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE {name: 'r2'}]->(b)
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 1        |
    And the side effects should be:
      | +relationships | 1 |
      | +properties    | 1 |

  Scenario: Matching incoming relationship
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (b)-[:TYPE]->(a)
      CREATE (a)-[:TYPE]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)<-[r:TYPE]-(b)
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 1        |
    And no side effects

  Scenario: Creating relationship with property
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE {name: 'Lola'}]->(b)
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 1        |
    And the side effects should be:
      | +relationships | 1 |
      | +properties    | 1 |

  Scenario: Using ON CREATE on a node
    Given an empty graph
    When executing query:
      """
      MERGE (a)-[:KNOWS]->(b)
        ON CREATE SET b.created = timestamp()
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +properties    | 1 |

  Scenario: Using ON CREATE on a relationship
    Given an empty graph
    And having executed:
      """
      CREATE (:A), (:B)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE]->(b)
        ON CREATE SET r.name = 'Lola'
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 1        |
    And the side effects should be:
      | +relationships | 1 |
      | +properties    | 1 |

  Scenario: Using ON MATCH on created node
    Given an empty graph
    When executing query:
      """
      MERGE (a)-[:KNOWS]->(b)
        ON MATCH SET b.created = timestamp()
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |

  Scenario: Using ON MATCH on created relationship
    Given an empty graph
    When executing query:
      """
      MERGE (a)-[r:KNOWS]->(b)
        ON MATCH SET r.created = timestamp()
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |

  Scenario: Using ON MATCH on a relationship
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE]->(b)
        ON MATCH SET r.name = 'Lola'
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 1        |
    And the side effects should be:
      | +properties | 1 |

  Scenario: Using ON CREATE and ON MATCH
    Given an empty graph
    And having executed:
      """
      CREATE (a:A {id: 1}), (b:B {id: 2})
      CREATE (a)-[:TYPE]->(b)
      CREATE (:A {id: 3}), (:B {id: 4})
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:TYPE]->(b)
        ON CREATE SET r.name = 'Lola'
        ON MATCH SET r.name = 'RUN'
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 4        |
    And the side effects should be:
      | +relationships | 3 |
      | +properties    | 4 |

  Scenario: Using a single bound node
    Given an empty graph
    And having executed:
      """
      CREATE (:A)
      """
    When executing query:
      """
      MATCH (a:A)
      MERGE (a)-[r:TYPE]->()
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 1        |
    And the side effects should be:
      | +nodes         | 1 |
      | +relationships | 1 |

  Scenario: Using a longer pattern
    Given an empty graph
    And having executed:
      """
      CREATE (:A)
      """
    When executing query:
      """
      MATCH (a:A)
      MERGE (a)-[r:TYPE]->()<-[:TYPE]-()
      RETURN count(r)
      """
    Then the result should be:
      | count(r) |
      | 1        |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 2 |

  Scenario: Using bound nodes in mid-pattern
    Given an empty graph
    And having executed:
      """
      CREATE (:B)
      """
    When executing query:
      """
      MATCH (b:B)
      MERGE (a)-[r1:TYPE]->(b)<-[r2:TYPE]-(c)
      RETURN type(r1), type(r2)
      """
    Then the result should be:
      | type(r1) | type(r2) |
      | 'TYPE'   | 'TYPE'   |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 2 |

  Scenario: Using bound nodes in mid-pattern when pattern partly matches
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:TYPE]->(b)
      """
    When executing query:
      """
      MATCH (b:B)
      MERGE (a:A)-[r1:TYPE]->(b)<-[r2:TYPE]-(c:C)
      RETURN type(r1), type(r2)
      """
    Then the result should be:
      | type(r1) | type(r2) |
      | 'TYPE'   | 'TYPE'   |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 2 |
      | +labels        | 2 |

  Scenario: Creating relationship using merged nodes
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      """
    When executing query:
      """
      MERGE (a:A)
      MERGE (b:B)
      MERGE (a)-[:FOO]->(b)
      """
    Then the result should be empty
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Mixing MERGE with CREATE
    Given an empty graph
    When executing query:
      """
      CREATE (a:A)
      MERGE (a)-[:KNOWS]->(b:B)
      CREATE (b)-[:KNOWS]->(c:C)
      RETURN count(*)
      """
    Then the result should be:
      | count(*) |
      | 1        |
    And the side effects should be:
      | +nodes         | 3 |
      | +relationships | 2 |
      | +labels        | 3 |

  Scenario: Failing when creation would violate constraint
    Given an empty graph
    And having executed:
      """
      CREATE CONSTRAINT ON (p:Person) ASSERT p.id IS UNIQUE
      """
    And having executed:
      """
      CREATE (:Person {id: 666})
      """
    When executing query:
      """
      CREATE (a:A)
      MERGE (a)-[:KNOWS]->(b:Person {id: 666})
      """
    Then a ConstraintValidationFailed should be raised at runtime: CreateBlockedByConstraint

  Scenario: Merging inside a FOREACH using a previously matched node
    Given an empty graph
    And having executed:
      """
      CREATE (s:S)
      CREATE (s)-[:FOO]->({prop: 2})
      """
    When executing query:
      """
      MATCH (a:S)
      FOREACH(x IN [1, 2, 3] |
        MERGE (a)-[:FOO]->({prop: x})
      )
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 2 |
      | +properties    | 2 |

  Scenario: Merging inside a FOREACH using a previously matched node and a previously merged node
    Given an empty graph
    And having executed:
      """
      CREATE (:S)
      CREATE (:End {prop: 42})
      """
    When executing query:
      """
      MATCH (a:S)
      FOREACH(x IN [42] |
        MERGE (b:End {prop: x})
        MERGE (a)-[:FOO]->(b)
      )
      """
    Then the result should be empty
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Merging inside a FOREACH using two previously merged nodes
    Given an empty graph
    And having executed:
      """
      CREATE ({x: 1})
      """
    When executing query:
      """
      FOREACH(v IN [1, 2] |
        MERGE (a {x: v})
        MERGE (b {y: v})
        MERGE (a)-[:FOO]->(b)
      )
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 3 |
      | +relationships | 2 |
      | +properties    | 3 |

  Scenario: Merging inside a FOREACH using two previously merged nodes that also depend on WITH
    Given an empty graph
    When executing query:
      """
      WITH 3 AS y
      FOREACH(x IN [1, 2] |
        MERGE (a {x: x, y: y})
        MERGE (b {x: x + 1, y: y})
        MERGE (a)-[:FOO]->(b)
      )
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 3 |
      | +relationships | 2 |
      | +properties    | 6 |

  Scenario: Introduce named paths 1
    Given an empty graph
    When executing query:
      """
      MERGE (a:A)
      MERGE p = (a)-[:R]->()
      RETURN p
      """
    Then the result should be:
      | p               |
      | <(:A)-[:R]->()> |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +labels        | 1 |

  Scenario: Introduce named paths 2
    Given an empty graph
    When executing query:
      """
      MERGE (a {x: 1})
      MERGE (b {x: 2})
      MERGE p = (a)-[:R]->(b)
      RETURN p
      """
    Then the result should be:
      | p                         |
      | <({x: 1})-[:R]->({x: 2})> |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +properties    | 2 |

  Scenario: Introduce named paths 3
    Given an empty graph
    When executing query:
      """
      MERGE p = (a {x: 1})
      RETURN p
      """
    Then the result should be:
      | p          |
      | <({x: 1})> |
    And the side effects should be:
      | +nodes      | 1 |
      | +properties | 1 |

  Scenario: Unbound pattern
    Given an empty graph
    When executing query:
      """
      MERGE ({name: 'Andres'})-[:R]->({name: 'Emil'})
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +properties    | 2 |

  Scenario: Inside nested FOREACH
    Given an empty graph
    When executing query:
      """
      FOREACH(x IN [0, 1, 2] |
        FOREACH(y IN [0, 1, 2] |
          MERGE (a {x: x, y: y})
          MERGE (b {x: x + 1, y: y})
          MERGE (c {x: x, y: y + 1})
          MERGE (d {x: x + 1, y: y + 1})
          MERGE (a)-[:R]->(b)
          MERGE (a)-[:R]->(c)
          MERGE (b)-[:R]->(d)
          MERGE (c)-[:R]->(d)
        )
      )
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 16 |
      | +relationships | 24 |
      | +properties    | 32 |

  Scenario: Inside nested FOREACH, nodes inlined
    Given an empty graph
    When executing query:
      """
      FOREACH(x IN [0, 1, 2] |
        FOREACH(y IN [0, 1, 2] |
          MERGE (a {x: x, y: y})-[:R]->(b {x: x + 1, y: y})
          MERGE (c {x: x, y: y + 1})-[:R]->(d {x: x + 1, y: y + 1})
          MERGE (a)-[:R]->(c)
          MERGE (b)-[:R]->(d)
        )
      )
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 24 |
      | +relationships | 30 |
      | +properties    | 48 |

  Scenario: ON CREATE on created nodes
    Given an empty graph
    When executing query:
      """
      MERGE (a)-[:KNOWS]->(b)
        ON CREATE SET b.created = timestamp()
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +properties    | 1 |

  Scenario: Use outgoing direction when unspecified
    Given an empty graph
    When executing query:
      """
      MERGE (a {id: 2})-[r:KNOWS]-(b {id: 1})
      RETURN startNode(r).id AS s, endNode(r).id AS e
      """
    Then the result should be:
      | s | e |
      | 2 | 1 |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +properties    | 2 |

  Scenario: Match outgoing relationship when direction unspecified
    Given an empty graph
    And having executed:
      """
      CREATE (a {id: 1}), (b {id: 2})
      CREATE (a)-[:KNOWS]->(b)
      """
    When executing query:
      """
      MERGE (a {id: 2})-[r:KNOWS]-(b {id: 1})
      RETURN r
      """
    Then the result should be:
      | r        |
      | [:KNOWS] |
    And no side effects

  Scenario: Match both incoming and outgoing relationships when direction unspecified
    Given an empty graph
    And having executed:
      """
      CREATE (a {id: 2}), (b {id: 1}), (c {id: 1}), (d {id: 2})
      CREATE (a)-[:KNOWS {name: 'ab'}]->(b)
      CREATE (c)-[:KNOWS {name: 'cd'}]->(d)
      """
    When executing query:
      """
      MERGE (a {id: 2})-[r:KNOWS]-(b {id: 1})
      RETURN r
      """
    Then the result should be:
      | r                     |
      | [:KNOWS {name: 'ab'}] |
      | [:KNOWS {name: 'cd'}] |
    And no side effects

  Scenario: Fail when imposing new predicates on already bound variable
    Given any graph
    When executing query:
      """
      MERGE (a:Foo)-[r:KNOWS]->(a:Bar)
      """
    Then a SyntaxError should be raised at compile time: VariableAlreadyBound

  Scenario: Using list properties via variable
    Given an empty graph
    When executing query:
      """
      CREATE (a:Foo), (b:Bar)
      WITH a, b
      UNWIND ['a,b', 'a,b'] AS str
      WITH a, b, split(str, ',') AS roles
      MERGE (a)-[r:FB {foobar: roles}]->(b)
      RETURN count(*)
      """
    Then the result should be:
      | count(*) |
      | 2        |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |
      | +labels        | 2 |
      | +properties    | 1 |

  Scenario: Matching using list property
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:T {prop: [42, 43]}]->(b)
      """
    When executing query:
      """
      MATCH (a:A), (b:B)
      MERGE (a)-[r:T {prop: [42, 43]}]->(b)
      RETURN count(*)
      """
    Then the result should be:
      | count(*) |
      | 1        |
    And no side effects

  Scenario: Using bound variables from other updating clause
    Given an empty graph
    When executing query:
      """
      CREATE (a)
      MERGE (a)-[:X]->()
      RETURN count(a)
      """
    Then the result should be:
      | count(a) |
      | 1        |
    And the side effects should be:
      | +nodes         | 2 |
      | +relationships | 1 |

  Scenario: UNWIND with multiple merges
    Given an empty graph
    When executing query:
      """
      UNWIND ['Keanu Reeves', 'Hugo Weaving', 'Carrie-Anne Moss', 'Laurence Fishburne'] AS actor
      MERGE (m:Movie {name: 'The Matrix'})
      MERGE (p:Person {name: actor})
      MERGE (p)-[:ACTED_IN]->(m)
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 5 |
      | +relationships | 4 |
      | +labels        | 5 |
      | +properties    | 5 |

  Scenario: Do not match on deleted entities
    Given an empty graph
    And having executed:
      """
      CREATE (a:A)
      CREATE (b1:B {value: 0}), (b2:B {value: 1})
      CREATE (c1:C), (c2:C)
      CREATE (a)-[:REL]->(b1),
             (a)-[:REL]->(b2),
             (b1)-[:REL]->(c1),
             (b2)-[:REL]->(c2)
      """
    When executing query:
      """
      MATCH (a:A)-[ab]->(b:B)-[bc]->(c:C)
      DELETE ab, bc, b, c
      MERGE (newB:B {value: 1})
      MERGE (a)-[:REL]->(newB)
      MERGE (newC:C)
      MERGE (newB)-[:REL]->(newC)
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 2 |
      | -nodes         | 4 |
      | +relationships | 2 |
      | -relationships | 4 |
      | +labels        | 2 |
      | +properties    | 1 |

  Scenario: Do not match on deleted relationships
    Given an empty graph
    And having executed:
      """
      CREATE (a:A), (b:B)
      CREATE (a)-[:T {name: 'rel1'}]->(b),
             (a)-[:T {name: 'rel2'}]->(b)
      """
    When executing query:
      """
      MATCH (a)-[t:T]->(b)
      DELETE t
      MERGE (a)-[t2:T {name: 'rel3'}]->(b)
      RETURN t2.name
      """
    Then the result should be:
      | t2.name |
      | 'rel3'  |
      | 'rel3'  |
    And the side effects should be:
      | +relationships | 1 |
      | -relationships | 2 |
      | +properties    | 1 |

  Scenario: Aliasing of existing nodes 1
    Given an empty graph
    And having executed:
      """
      CREATE ({id: 0})
      """
    When executing query:
      """
      MATCH (n)
      MATCH (m)
      WITH n AS a, m AS b
      MERGE (a)-[r:T]->(b)
      RETURN a.id AS a, b.id AS b
      """
    Then the result should be:
      | a | b |
      | 0 | 0 |
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Aliasing of existing nodes 2
    Given an empty graph
    And having executed:
      """
      CREATE ({id: 0})
      """
    When executing query:
      """
      MATCH (n)
      WITH n AS a
      MERGE (a)-[r:T]->(b)
      RETURN a.id AS a
      """
    Then the result should be:
      | a |
      | 0 |
    And the side effects should be:
      | +nodes         | 1 |
      | +relationships | 1 |

  Scenario: Double aliasing of existing nodes 1
    Given an empty graph
    And having executed:
      """
      CREATE ({id: 0})
      """
    When executing query:
      """
      MATCH (n)
      MATCH (m)
      WITH n AS a, m AS b
      MERGE (a)-[:T]->(b)
      WITH a AS x, b AS y
      MERGE (a)-[:T]->(b)
      RETURN x.id AS x, y.id AS y
      """
    Then the result should be:
      | x | y |
      | 0 | 0 |
    And the side effects should be:
      | +relationships | 1 |

  Scenario: Double aliasing of existing nodes 2
    Given an empty graph
    And having executed:
      """
      CREATE ({id: 0})
      """
    When executing query:
      """
      MATCH (n)
      WITH n AS a
      MERGE (a)-[:T]->()
      WITH a AS x
      MERGE (x)-[:T]->()
      RETURN x.id AS x
      """
    Then the result should be:
      | x |
      | 0 |
    And the side effects should be:
      | +nodes         | 1 |
      | +relationships | 1 |
