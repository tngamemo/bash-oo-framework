#!/usr/bin/env bash

__INTERNAL_LOGGING__=true
source "$( cd "${BASH_SOURCE[0]%/*}" && pwd )/../lib/oo-framework.sh"

namespace seamless

Log.AddOutput seamless CUSTOM
#Log.AddOutput oo/parameters-executing CUSTOM

alias @="Exception.CustomCommandHandler"

String.GetRandomAlphanumeric() {
    # http://stackoverflow.com/a/23837814/595157
    local chars=( {a..z} {A..Z} {0..9} )
    local length=$1
    local ret=
    while ((length--))
    do
        ret+=${chars[$((RANDOM%${#chars[@]}))]}
    done
    printf '%s\n' "$ret"
}

Type.CreateVar() {
    # USE DEFAULT IFS IN CASE IT WAS CHANGED - important!
    local IFS=$' \t\n'
    
    local commandWithArgs=( $1 )
    local command="${commandWithArgs[0]}"

    shift

    if [[ "$command" == "trap" || "$command" == "l="* || "$command" == "_type="* ]]
    then
        return 0
    fi

    if [[ "${commandWithArgs[*]}" == "true" ]]
    then
        __typeCreate_next=true
        # Console.WriteStdErr "Will assign next one"
        return 0
    fi

    local varDeclaration="${commandWithArgs[1]}"
    if [[ $varDeclaration == '-'* ]]
    then
        varDeclaration="${commandWithArgs[2]}"
    fi
    local varName="${varDeclaration%%=*}"

    # var value is only important if making an object later on from it
    local varValue="${varDeclaration#*=}"

    if [[ ! -z $__typeCreate_varType ]]
    then
        # Console.WriteStdErr "SETTING $__typeCreate_varName = \$$__typeCreate_paramNo"
        # Console.WriteStdErr --
        #Console.WriteStdErr $tempName

    	DEBUG Log "creating $__typeCreate_varName ($__typeCreate_varType)"
    	
    	# __oo__objects+=( $__typeCreate_varName )

        unset __typeCreate_varType
    fi

    if [[ "$command" != "declare" || "$__typeCreate_next" != "true" ]]
    then
        __typeCreate_normalCodeStarted+=1

        # Console.WriteStdErr "NOPASS ${commandWithArgs[*]}"
        # Console.WriteStdErr "normal code count ($__typeCreate_normalCodeStarted)"
        # Console.WriteStdErr --
    else
        unset __typeCreate_next

        __typeCreate_normalCodeStarted=0
        __typeCreate_varName="$varName"
        __typeCreate_varType="$__capture_type"
        __typeCreate_arrLength="$__capture_arrLength"

        # Console.WriteStdErr "PASS ${commandWithArgs[*]}"
        # Console.WriteStdErr --

        __typeCreate_paramNo+=1
    fi
}

Type.CaptureParams() {
    # Console.WriteStdErr "Capturing Type $_type"
    # Console.WriteStdErr --

    __capture_type="$_type"
}
    
# NOTE: true; true; at the end is required to workaround an edge case where TRAP doesn't behave properly
alias trapAssign='Type.CaptureParams; declare -i __typeCreate_normalCodeStarted=0; trap "declare -i __typeCreate_paramNo; Type.CreateVar \"\$BASH_COMMAND\" \"\$@\"; [[ \$__typeCreate_normalCodeStarted -ge 2 ]] && trap - DEBUG && unset __typeCreate_varType && unset __typeCreate_varName && unset __typeCreate_paramNo" DEBUG; true; true; '
alias reference='_type=reference trapAssign declare -n'
alias var='_type=var trapAssign declare'
alias int='_type=int trapAssign declare -i'
alias array='_type=array trapAssign declare -a'
alias dictionary='_type=dictionary trapAssign declare -A'

myFunction() {
    array something # creates object "something" && __oo__garbageCollector+=( something ) local -a something
    array another
    something.Add "blabla"
    something.Add $ref:something
    # for member in "${something[@]}"
    Array.Merge $ref:something $ref:another
}

declare -Ag __oo__garbageCollector


# we don't need to define anything if using command_not_found
# we only need to check what type that variable is!
# and return whatever we need!
# it also means we can PIPE to a variable/object
# echo dupa | someArray.Add

alias @modifiesLocals="[[ \"\${FUNCNAME[2]}\" != \"command_not_found_handle\" ]] || subject=warn Log \"Method \$FUNCNAME modifies locals and needs to be run prefixed by '@'\""

writeln() ( # forking for local scope for $IFS
	local IFS=" " # needed for "$*"
	printf '%s\n' "$*"
)

write() (
	local IFS=" "
	printf %s "$*"
)

writelne() (
	local IFS=" "
	printf '%b\n' "$*"
)

obj=OBJECT

Object.New() {
	local ObjectUUID=$obj:$(String.GetRandomAlphanumeric 12)
}

Object.IsObject() {
	:
}

Object.GetType() {
	:
}

Reference.GetRealVariableName() {
	local realObject="$1"
	# local typeInfo="$(declare -p $realObject 2> /dev/null || declare -p | grep "^declare -[aAign\-]* $realObject\(=\|$\)" || true)"
	local typeInfo="$(declare -p $realObject 2> /dev/null || true)"

	if [[ -z "$typeInfo" ]]
	then
		DEBUG local extraInfo="$(declare -p | grep "^declare -[aAign\-]* $realObject\(=\|$\)" || true)"
		DEBUG subject="dereferrenceNoSuccess" Log "$extraInfo"
		echo "$realObject"
		return 0
	fi

	#DEBUG subject="dereferrence" Log "$realObject to $typeInfo"
	# dereferrence
	while [[ "$typeInfo" =~ "declare -n" ]] && [[ "$typeInfo" =~ \"([a-zA-Z0-9_]*)\" ]]
	do
		DEBUG subject="dereferrence" Log "$realObject to ${BASH_REMATCH[1]}"
		realObject=${BASH_REMATCH[1]}
		typeInfo="$(declare -p $realObject 2> /dev/null)" # || declare -p | grep "^declare -[aAign\-]* $realObject\(=\|$\)"
	done

	echo "$realObject"
}

Variable.GetType() {
	local typeInfo="$(declare -p $1 2> /dev/null || declare -p | grep "^declare -[aAign\-]* $1\(=\|$\)" || true)"
	# local typeInfo="$(declare -p $1 2> /dev/null || true)"

	if [[ -z "$typeInfo" ]]
	then
		echo undefined
		return 0
	fi

	if [[ "$typeInfo" == "declare -n"* ]]
	then
		echo reference
	elif [[ "$typeInfo" == "declare -a"* ]]
	then
		echo array
	elif [[ "$typeInfo" == "declare -A"* ]]
	then
		echo dictionary
	elif [[ "$typeInfo" == "declare -i"* ]]
	then
		echo integer
	# elif [[ "${!1}" == "$obj:"* ]]
	# then
	# 	echo "$(Object.GetType "${!realObject}")"
	else
		echo string
	fi
}

# insted of echo let's use $return
# return="something"
# return should be declared prior to entering the func

@returns() {
	@var returnType
	# switch case array
	# check if $return is an array
	# etc...
	#:

	# initialize/reset return variable:
	case "$returnType" in
		'array' | 'dictionary') return=() ;;
		'string' | 'integer') return="";;
		*) ;;
	esac

	# DEBUG subject="returnsMatch" Log 
	local realVar=$(Reference.GetRealVariableName return)
	local type=$(Variable.GetType $realVar)

	# if [[ $type == reference ]]
	# then
	# 	type=$(Reference.GetRealVariableName return)
	# fi

	# local typeInfo="$(declare -p return)"
	# # first dereferrence
	# # maybe this should be "while" for recursive dereferrence?
	# while [[ "$typeInfo" =~ "declare -n" ]] && [[ "$typeInfo" =~ \"([a-zA-Z0-9_]*)\" ]]
	# do
	# 	local realObject=${BASH_REMATCH[1]}
	# 	typeInfo="$(declare -p $realObject)"
	# done

	# if [[ "$typeInfo" == "declare -a"* ]]
	# then
	# 	local type=array
	# elif [[ "$typeInfo" == "declare -A"* ]]
	# then
	# 	local type=dictionary
	# elif [[ "$typeInfo" == "declare -i"* ]]
	# then
	# 	local type=integer
	# elif [[ "${!realObject}" == "$obj:"* ]]
	# then
	# 	local type=$(Object.GetType "${!realObject}")
	# else
	# 	local type=string
	# fi

	if [[ "$returnType" != "$type" ]]
	then
		e="Return type ($returnType) doesn't match with the actual type ($type)." throw
	fi

}

string.length() {
	return=${#this}
}

array.length() {
	@returns int
	return=${#this[@]}
}

string.sanitized() {
    local sanitized="${this//[^a-zA-Z0-9]/_}"
    return="${sanitized^^}"
}

string.toArray() {
	#@reference array
	@modifiesLocals

	local newLine=$'\n'
	local separationCharacter=$'\UFAFAF'
	local string="${this//"$newLine"/"$separationCharacter"}"
	local IFS=$separationCharacter
	local element
	for element in $string
	do
		return+=( "$element" )
	done

	local newLines=${string//[^$separationCharacter]}
	local -i trailingNewLines=$(( ${#newLines} - ${#return[@]} + 1 ))
	while (( trailingNewLines-- ))
	do
		return+=( "" )
	done
}

array.print() {
	local index
	for index in "${!this[@]}"
	do
		echo "$index: ${this[$index]}"
	done
}

string.change() {
	## EXAMPLE
	@modifiesLocals
	# [[ "${FUNCNAME[2]}" != "command_not_found_handle" ]] || s=warn Log "Method $FUNCNAME modifies locals and needs to be run prefixed by '@'."
	this="somethingElse"
}

string.match() {
	@var regex
	@int capturingGroup=${bracketParams[0]} #bracketParams
	@var returnMatch="${bracketParams[1]}"

	DEBUG subject="string.match" Log "string to match on: $this"
	local -a allMatches=()
	@ allMatches~=this.matchGroups "$regex" "$returnMatch"
	#allMatches.print
	return="${allMatches[$capturingGroup]}"
}

string.matchGroups() {
	@returns array
	@var regex
	# @reference matchGroups
	@var returnMatch="${bracketParams[0]}"

	DEBUG subject="matchGroups" Log "string to match on: $this" 
	local -i matchNo=0
	local string="$this"
	while [[ "$string" =~ $regex ]]
	do
		subject="regex" Log "match $matchNo: ${BASH_REMATCH[*]}"

		if [[ "$returnMatch" == "@" || $matchNo -eq "$returnMatch" ]]
		then
			return+=( "${BASH_REMATCH[@]}" )
			[[ "$returnMatch" == "@" ]] || return 0
		fi
		# cut out the match so we may continue
		string="${string/"${BASH_REMATCH[0]}"}" # "
		matchNo+=1
	done
}

array.takeEvery() {
	@returns array
	@int every
	@int startingIndex
	# @reference outputArray

	local -i count=0

	local index
	for index in "${!this[@]}"
	do
		if [[ $index -eq $(( $every * $count + $startingIndex )) ]]
		then
			#echo "$index: ${this[$index]}"
			return+=( "${this[$index]}" )
			count+=1
		fi
	done
}

array.last() {
	local count="${#this[@]}"
	echo "${this[($count-1)]}"
}

array.forEach() {
	@var elementName
	@var do

	# first dereferrence
	# local typeInfo="$(declare -p this)"
	# if [[ "$typeInfo" =~ "declare -n" ]] && [[ "$typeInfo" =~ \"([a-zA-Z0-9_]*)\" ]]
	# then
	# 	local realName=${BASH_REMATCH[1]}
	# fi

	local index
	for index in "${!this[@]}"
	do
		local $elementName="${this[$index]}"
		# local -n $elementName="$realName[$index]"
		# local -n $elementName="this[$index]"
		eval "$do"
		# unset -n $elementName
	done
}

Exception.CustomCommandHandler() {
	# best method for checking if variable is declared: http://unix.stackexchange.com/questions/56837/how-to-test-if-a-variable-is-defined-at-all-in-bash-prior-to-version-4-2-with-th
	if [[ ! "$1" =~ \. ]] && [[ -n ${!1+isSet} ]]
	then
		# check if an object UUID
		# else print var
		DEBUG subject="builtin" Log "Invoke builtin getter"
		# echo "var $1=${!1}"
		echo "${!1}"
	else
		local regex='(^|\.)([a-zA-Z0-9_]+)(({[^}]*})*)((\[[^]]*\])*)((\+=|-=|\*=|/=|==|\+\+|~=|:=|=|\+|/|\\|\*|~|:|-)(.*))*'

		local -a matches
		local -n return=matches; this="$1" bracketParams=@ string.matchGroups "$regex"; unset -n return

		if (( ${#matches[@]} == 0 ))
		then
			return 1
		fi

		local -a callStack
		local -a callStackParams
		local -a callStackLastParam
		local -a callStackBrackets
		local -a callStackLastBracket
		local callOperator="${matches[-2]}"
		local callValue="${matches[-1]}"

		#unset -n this
		local originalThisReference="$(Reference.GetRealVariableName this)"
		DEBUG [[ ${originalThisReference} == this ]] || subject="originalThisReference" Log $originalThisReference
		[[ ${originalThisReference} != this ]] || local originalThis="$this"

		local -n this="matches"
			local -n return=callStack; array.takeEvery 10 2; unset -n return
			local -n return=callStackParams; array.takeEvery 10 3; unset -n return
			local -n return=callStackLastParam; array.takeEvery 10 4; unset -n return
			local -n return=callStackBrackets; array.takeEvery 10 5; unset -n return
			local -n return=callStackLastBracket; array.takeEvery 10 6; unset -n return
		unset -n this

		# restore the reference/value:
		[[ ${originalThisReference} == this ]] || local -n this="$originalThisReference"
		[[ -z ${originalThis} ]] || local this="$originalThis"

		# local -n this="callStack"
		# 	subject="complex" Log callStack:
		# 	array.print
		# unset -n this

		# local -n this="callStackParams"
		# 	subject="complex" Log callStackParams:
		# 	array.print
		# unset -n this
		
		# local -n this="callStackBrackets"
		# 	subject="complex" Log callStackBrackets:
		# 	array.print
		# unset -n this

		#DEBUG subject="complex" Log this: ${this[@]}
		DEBUG subject="complex" Log callOperator: $callOperator
		DEBUG subject="complex" Log callValue: $callValue
		#DEBUG subject="complex" Log

		local -i callLength=$((${#callStack[@]} - 1))
		local -i callHead=1

		DEBUG subject="complex" Log callLength: $callLength

		local rootObject="${callStack[0]}"

		# check for existance of $callStack[0] and whether it is an object
		# if is resolvable immediately
		local rootObjectResolvable=$rootObject[@]
		if [[ -n ${!rootObjectResolvable+isSet} || "$(eval "echo \" \${!$rootObject*} \"")" == *" $rootObject "* ]]
		then
			local realVar=$(Reference.GetRealVariableName $rootObject)
			local type=$(Variable.GetType $realVar)
			DEBUG subject="variable" Log "Variable \$$realVar of type: $type"

			if [[ $type == string && "${!rootObject}" == "$obj:"* ]]
			then
				# pass the rest of the call stack to the object invoker
				Object.Invoke "${!rootObject}" "${@:2}"
				return 0
			fi

			# #DEBUG subject="complex" Log "Current contents of $(eval "echo \" \${!$rootObject*} \""): ${!rootObject}"
			# local typeInfo="$(declare -p $rootObject 2> /dev/null || declare -p | grep "^declare -[aAign\-]* mik\(=\|$\)" )"

			# # first dereferrence
			# # maybe this should be "while" for recursive dereferrence?
			# while [[ "$typeInfo" =~ "declare -n" ]] && [[ "$typeInfo" =~ \"([a-zA-Z0-9_]*)\" ]]
			# do
			# 	rootObject=${BASH_REMATCH[1]}
			# 	typeInfo="$(declare -p $rootObject 2> /dev/null || declare -p | grep "^declare -[aAign\-]* mik\(=\|$\)" )"
			# done

			# if [[ "$typeInfo" == "declare -a"* ]]
			# then
			# 	local type=array
			# 	#local -n this="$rootObject"
			# elif [[ "$typeInfo" == "declare -A"* ]]
			# then
			# 	local type=dictionary
			# 	#local -n this="$rootObject"
			# elif [[ "$typeInfo" == "declare -i"* ]]
			# then
			# 	local type=integer
			# 	#local value="${!rootObject}"
			# elif [[ "${!rootObject}" == "$obj:"* ]]
			# then
			# 	# pass the rest of the call stack to the object invoker
			# 	Object.Invoke "${!rootObject}" "${@:2}"
			# 	return 0
			# else
			# 	local type=string
			# 	#local value="${!rootObject}"
			# fi

			if (( $callLength == 0 )) && [[ -n "$callOperator" ]]
			then
				DEBUG subject="complex" Log "CallStack length is 0, using the operator."
				case "$callOperator" in
					'~=') 
						  if [[ "${!callValue}" == "$obj:"* && -z "${*:2}" ]]
						  then
						  	eval "$rootObject=\"\${!callValue}\""
						  elif [[ -n "${callValue}" ]]
					  	  then
						  	# local -n returnValue="$rootObject"
						  	# __oo__useReturnValue=true @ $callValue "${@:2}"
						  	# (
						  	# declare -p this
						  	# local returnValue=$(
						  		#unset -n this

					  		#DEBUG subject="complexAssignment" Log "New Value for $callValue ${*:2} === $($callValue "${@:2}")"
						  		# )
						  	
						  	# local originalThis="$(Reference.GetRealVariableName this)"
						  	# DEBUG subject="complexAssignment" Log "This is set to: $originalThis"

						  	#[[ -n ${originalThis+isSet} ]] || 
						  	# unset -n this
						  	# local -n this="$rootObject"
						  	
						  	#eval "$callValue \"\${@:2}\""
						  	# [[ -n ${originalThis+isSet} ]] || unset -n this
						  	# [[ -n ${originalThis+isSet} ]] || local -n this="$originalThis"
						  	# )
						  	# local echoOut="$($callValue "${@:2}")"
						  	# if [[ -n "${echoOut}" ]]
					  		# then
					  		# 	DEBUG subject="complexAssignment" Log "$echoOut |vs| $return"
						  	# 	returnValue="$echoOut"
						  	# fi
						  	# unset -n returnValue
						  	eval "$rootObject=\$($callValue \"\${@:2}\")"
						  fi
						  DEBUG subject="complexAssignment" Log "$rootObject=${!rootObject}"
						  ;;
				esac
				# $type.$callOperator "$callValue" "${@:2}"
			else
				while ((callLength--))
				do
					DEBUG subject="complex" Log calling: $type.${callStack[$callHead]}
					# does the method exist?
					if ! Function.Exists $type.${callStack[$callHead]}
					then
						e="Method: $type.${callStack[$callHead]} does not exist." skipBacktraceCount=4 throw ${callStack[$callHead]}
					fi

					local -a mustacheParams=()
					local mustacheParamsRegex='[^{}]+'
					local -n return=mustacheParams; this="${callStackParams[$callHead]}" bracketParams=@ string.matchGroups "$mustacheParamsRegex"; unset -n return

					local -a bracketParams=()
					local bracketRegex='[^][]+'
					local -n return=bracketParams; this="${callStackBrackets[$callHead]}" string.matchGroups "$bracketRegex" @; unset -n return

					DEBUG subject="complex" Log bracketParams: ${bracketParams[*]} #${callStackParams[$callHead]}
					DEBUG subject="complex" Log mustacheParams: ${mustacheParams[*]} #${callStackBrackets[$callHead]}
					DEBUG subject="complex" Log --

					#local originalThis="$(Reference.GetRealVariableName this)"
					case "$type" in 
						"array"|"dictionary") local -n this="$rootObject" ;;
						"integer"|"string") local value="${!rootObject}" ;;
					esac
					
					# if (( $callLength == 1 )) && [[ -n "$callOperator" ]]
					# then
					if (( $callHead == 1 )) && ! [[ "$type" == "string" || "$type" == "integer" ]]
					then
						$type.${callStack[$callHead]} "${@:2}"
					else
						local newValue
						local -n return=newValue
						this="$value" $type.${callStack[$callHead]} "${mustacheParams[@]}" "${@:2}"
						value="$newValue"
						unset -n return
						# value=$(this="$value" $type.${callStack[$callHead]} "${@:2}")
					fi
					# fi

					unset -n this

					callHead+=1
				done

				if [[ -n ${value+isSet} ]]
				then
					# if [[ -n ${__oo__useReturnValue+isSet} ]]
					# then
						# returnValue="${value}"
					# else
						echo "${value}"
					# fi
				fi
			fi

			#DEBUG subject="complex" Log "Invoke type: $type, object: $rootObject, ${child:+child: $child, }${bracketOperator:+"$bracketOperator: $bracketParams, "}operator: $operator${parameter:+, param $parameter}"
			
			#$type${child:+".$child"} "${@:2}"
		else
			#eval "echo \" \${!$rootObject*} \""
			DEBUG subject="complex" Log ${rootObjectResolvable} is not resolvable: ${!rootObjectResolvable}
			return 1
		fi
	fi
	# if callOperator then for sure an object - check if exists, else error
	
}

# testFunc() {
	# local testing="onething.object['abc def'].length[123].something[2]{another}"
	#local testing="something.somethingElse{var1,var2,var3}[a].extensive{param1 : + can be =\"anything \"YO # -yo space}{another}[0][2]=LALALA} and what if=we have.an equals.test[immi]{lol}?"
	# local something="haha haha Yo!"
	# local testing="something.sanitized{}.length{}"
	# local -a dupa
	# dupa~=something.toArray -- use dupa as output parameter/ret-val
	#local regex='(?:^|\.)([a-zA-Z0-9_]+)((?:{.*?})*)((?:\[.*?\])*)(?:(=|\+|/|\\|\*|~|:|-|\+=|-=|\*=|/=|==)(.*))*'

# testFunc

testFunc2() {
	local something="haha haha Yo!"
	local another="hey! works!"
	# something
	# another
	# something.sanitized{}.length{}.length{}
	# something.sanitized{}
	@ something~="another.sanitized{}"
	something
	something.match{'WOR.*'}[0][0]
}

testFunc2

# new method for a type system:
#
# command_not_found_handle() {
# 	echo hi, "$*" "${!2}"
# }
# declare jasia="haha"
# dupa jasia

# readPipe() {
# 	read it
# 	read
# }

# shopt -s lastpipe
# echo "hello world" | readPipe
# echo $it
