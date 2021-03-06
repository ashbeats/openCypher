/*
 * Copyright (c) 2015-2016 "Neo Technology,"
 * Network Engine for Objects in Lund AB [http://neotechnology.com]
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.opencypher.grammar;

import java.util.Objects;

import org.opencypher.tools.xml.Attribute;
import org.opencypher.tools.xml.Element;

import static java.util.Objects.requireNonNull;

@Element(uri = Grammar.XML_NAMESPACE, name = "non-terminal")
final class NonTerminalNode extends Node implements NonTerminal
{
    @Attribute
    String ref;
    @Attribute(uri = Grammar.RAILROAD_XML_NAMESPACE, optional = true)
    Boolean skip, inline;
    @Attribute(uri = Grammar.RAILROAD_XML_NAMESPACE, optional = true)
    String title;
    private ProductionNode production;
    private int index = -1;
    private ProductionNode origin;

    @Override
    public Production production()
    {
        return production;
    }

    @Override
    public boolean skip()
    {
        return skip == null ? production.skip : skip;
    }

    @Override
    public boolean inline()
    {
        return inline == null ? production.inline : inline;
    }

    @Override
    public String title()
    {
        return title == null ? production.name : title;
    }

    @Override
    public Production declaringProduction()
    {
        return origin;
    }

    @Override
    void resolve( ProductionNode origin, ProductionResolver resolver )
    {
        production = resolver.resolveProduction( origin, requireNonNull( ref, "non-terminal reference" ) );
        if ( production != null )
        {
            production.addReference( this );
            if ( index < 0 )
            {
                this.origin = origin;
                index = resolver.nextNonTerminalIndex();
            }
        }
    }

    @Override
    public int hashCode()
    {
        return Objects.hashCode( ref );
    }

    @Override
    public boolean equals( Object obj )
    {
        if ( this == obj )
        {
            return true;
        }
        if ( obj.getClass() != NonTerminalNode.class )
        {
            return false;
        }
        NonTerminalNode that = (NonTerminalNode) obj;
        return /*this.production == that.production &&*/ Objects.equals( this.ref, that.ref );
    }

    @Override
    public String toString()
    {
        return "NonTerminal{" + ref + "}";
    }

    @Override
    public <P, T, EX extends Exception> T transform( TermTransformation<P, T, EX> transformation, P param ) throws EX
    {
        return transformation.transformNonTerminal( param, this );
    }
}
