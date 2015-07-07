#if MIN_VERSION_base(4,8,0)
import Control.Applicative ((<$>))
#else
import Control.Applicative (Applicative(..), (<$>))
import Data.Monoid (Monoid(..))
import Data.Traversable (Traversable(traverse))
#endif
#if __GLASGOW_HASKELL__
import GHC.Exts ( build )
#endif
#if __GLASGOW_HASKELL__ >= 708
import qualified GHC.Exts as GHCExts
#endif
