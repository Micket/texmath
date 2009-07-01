module Text.TeXMath.MathMLWriter (toMathML, DisplayType(..), showExp)
where

import qualified Data.Map as M
import Text.XML.Light
import Text.TeXMath.Parser

data DisplayType = DisplayBlock
                 | DisplayInline
                 deriving Show

toMathML :: DisplayType -> [Exp] -> Element
toMathML dt exprs =
  add_attr dtattr $ math $ map showExp exprs
    where dtattr = Attr (unqual "display") dt'
          dt' =  case dt of
                      DisplayBlock  -> "block"
                      DisplayInline -> "inline"

math :: [Element] -> Element
math = add_attr (Attr (unqual "xmlns") "http://www.w3.org/1998/Math/MathML") . unode "math"

mrow :: [Element] -> Element
mrow = unode "mrow"

{- Firefox seems to set spacing based on its own dictionary,
-  so I believe this is unnecessary.
 
setSpacing :: String -> String -> Bool -> Element -> Element
setSpacing left right stretchy elt =
  add_attr (Attr (unqual "lspace") left) $
  add_attr (Attr (unqual "rspace") right) $
  if stretchy
     then add_attr (Attr (unqual "stretchy") "true") elt
     else elt

showSymbol (ESymbol s x) =
  case s of
    Ord   x  -> unode "mo" x
    Op    x  -> setSpacing "0" "0.167em" True $ unode "mo" x
    Bin   x  -> setSpacing "0.222em" "0.222em" False $ unode "mo" x
    Rel   x  -> setSpacing "0.278em" "0.278em" False $ unode "mo" x
    Open  x  -> setSpacing "0" "0" True $ unode "mo" x
    Close x  -> setSpacing "0" "0" True $ unode "mo" x
    Pun   x  -> setSpacing "0" "0.167em" False $ unode "mo" x
-}

unaryOps :: M.Map String String
unaryOps = M.fromList
  [ ("\\sqrt", "msqrt")
  , ("\\surd", "msqrt")
  ]

showUnary :: String -> Exp -> Element
showUnary c x =
  case M.lookup c unaryOps of
       Just c'  -> unode c' (showExp x)
       Nothing  -> error $ "Unknown unary op: " ++ c

binaryOps :: M.Map String String
binaryOps = M.fromList
  [ ("\\frac", "mfrac")
  , ("\\sqrt", "mroot")
  , ("\\stack", "mover")
  ]

showBinary :: String -> Exp -> Exp -> Element
showBinary c x y =
  case M.lookup c binaryOps of
       Just c'  -> unode c' [showExp x, showExp y]
       Nothing  -> error $ "Unknown binary op: " ++ c

spaceWidth :: String -> Element
spaceWidth w =
  add_attr (Attr (unqual "width") w) $ unode "mspace" ()

makeStretchy :: Element -> Element
makeStretchy = add_attr (Attr (unqual "stretchy") "true")

makeScaled :: String -> Element -> Element
makeScaled s = add_attr (Attr (unqual "minsize") s) .
               add_attr (Attr (unqual "maxsize") s) 

showExp :: Exp -> Element
showExp e =
 case e of
   EInteger x     -> unode "mn" $ show x
   EFloat   x     -> unode "mn" $ show x
   EGrouped xs    -> mrow $ map showExp xs
   EIdentifier x  -> unode "mi" x
   ESymbol _ x    -> unode "mo" x
   ESpace x       -> spaceWidth x
   EBinary c x y  -> showBinary c x y
   ESub x y       -> unode "msub" $ map showExp [x, y]
   ESuper x y     -> unode "msup" $ map showExp [x, y]
   ESubsup x y z  -> unode "msubsup" $ map showExp [x, y, z]
   EUnary c x     -> showUnary c x
   EStretchy x    -> makeStretchy $ showExp x
   EScaled s x    -> makeScaled s $ showExp x